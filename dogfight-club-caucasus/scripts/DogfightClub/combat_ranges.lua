
local CombatRangeManagers = {}

for _, RangeZone in ipairs(ZONE:FindAllByMatching("^Combat Range.*")) do
    local CombatRange = {
        Name = RangeZone:GetName(),
        GroupTypeFlag = 1,              -- the currently selected vehicle type to spawn
        GroupSizeFlag = 1,              -- the currently selected number of units to spawn
        Groups = {},                    -- a table of vehicles names (strings)
        ClientMenus = {},                -- menu instances for each client (SET_CLIENT and CLIENTMENUMANAGER don't work)
        RangeZone = RangeZone,          -- the range zone
        SpawnZone = ZONE:FindByName("Spawn " .. RangeZone:GetName()),          -- the location where units will be spawned
        Templates = GROUP:FindAllByMatching(RangeZone:GetName() .. ".+"),      -- the templates used by the range
        SpawnCount = 0,                 -- required for crappy dcs spawn logic, removes need to keep spawners
        AI_Controller = nil,
    }
    -- spawn zones are PREFIXED with Spawn to prevent them being caught by the "FindAllByMatching" call

    function CombatRange:SetGroupType(index)
        -- set the index of the airframe to spawn in the group map
        self.GroupTypeFlag = index
    end
    function CombatRange:SetGroupSize(size)
        -- set the number of units in the group to spawn
        self.GroupSizeFlag = math.max(1, size)
    end
    function CombatRange:SpawnAircraftBasedOnFlags()
        -- here i lost my sanity
        -- this may look simple, but this is the worst api ive ever used
        -- and ive used java
        local airframe_name = self.Groups[self.GroupTypeFlag]
        local template_name = self.Name .. " " .. airframe_name
        local template_group = GROUP:FindByName(template_name)

        local template = template_group:GetTemplate()
        local spawned_name = "Spawned Group " .. self.Name .. " " .. airframe_name

        local speed_kph = 833.4 -- 450kts
        local altitude_m = template_group:GetAltitude(false)

        local spawn_coordinate = COORDINATE:NewFromVec3(self.SpawnZone:GetVec3(altitude_m))
        local range_coordinate = COORDINATE:NewFromVec3(self.RangeZone:GetVec3(altitude_m))

        -- api writer: I have no idea what I'm doing
        local heading = spawn_coordinate:GetAngleDegrees(spawn_coordinate:GetDirectionVec3(range_coordinate:GetVec3()))

        -- clone the unit so we have N of them
        local unit_template = template["units"][1]
        for i = 2, self.GroupSizeFlag do
            template["units"][i] = copytable(unit_template)
        end

        local positions = {}
        local offset = 20
        for i = 1, self.GroupSizeFlag do
            local relative_offset = offset * (i - 1)
            positions[i] = {x=relative_offset, y=relative_offset, heading=heading}
        end

        local spawner = SPAWN:NewFromTemplate(template, spawned_name)
        local spawned_group = spawner
            :InitCountry(country.id.RUSSIA)
            :InitCoalition(coalition.side.RED)
            :InitHeading(heading)
            :InitPositionCoordinate(spawn_coordinate)
            :InitSetUnitRelativePositions(positions)
            :Spawn()

        if spawned_group ~= nil then
            --spawned_group:PatrolRaceTrack(range_coordinate, spawn_coordinate, altitude_m, speed_kph)
            local patrol_alt_min_m = 4572 -- 15,000ft
            local patrol_alt_max_m = 10668 -- 35,000ft
            local patrol_speed_min_kmh = 777.84 -- 420kts
            local patrol_speed_max_kmh = 1481.6 -- 800kts
            self.AI_Controller = AI_CAP_ZONE:New(self.RangeZone, patrol_alt_min_m, patrol_alt_max_m, patrol_speed_min_kmh, patrol_speed_max_kmh)
            self.AI_Controller:SetControllable(spawned_group)
            self.AI_Controller:SetEngageZone(self.RangeZone)
            self.AI_Controller:__Start( 1 )

            MESSAGE:New(self.Name .. ": Spawned " .. self.GroupSizeFlag .. "x " .. airframe_name, 10, "Air Threat"):ToAll()
        else
            MESSAGE:New(self.Name .. ": Failed to spawn group", 10, "Air Threat"):ToAll()
        end
    end
    function CombatRange:Despawn()
        for _, obj in ipairs(GROUP:FindAllByMatching("Spawned Group " .. self.Name .. ".*")) do
            MESSAGE:New("Deleting " .. obj:GetName() .. " in " .. self.Name, 5, "De-spawn"):ToAll()
            obj:Destroy()
        end
    end
    function CombatRange:DiscoverTemplates()
        for _, obj in ipairs(self.Templates) do
            local group_name = obj:GetName()
            local vehicle_name = group_name:removeprefix(self.Name .. " ")
            table.insert(CombatRange.Groups, vehicle_name)
        end
        table.sort(CombatRange.Groups)
    end
    function CombatRange:AddMenuToClient(client)
        local ClientMenu = CLIENTMENUMANAGER:New(client)

        local RangeMenu         = ClientMenu:NewEntry(CombatRange.Name)
        local RangeMenu_Airframe    = RangeMenu:NewEntry("Airframe")
        if self.Groups and #self.Groups > 0 then
            -- limit menu to 9 items, 10 is next, 11 is previous, 12 is exit
            local ParentMenu = RangeMenu_Airframe
            for index, unit_name in ipairs(self.Groups) do
                if math.fmod(index, 10) == 0 then
                    ParentMenu          = ParentMenu:NewEntry("Next")
                end
                local Airframe          = ParentMenu:NewEntry(unit_name, function() CombatRange:SetGroupType(index) end)
            end
        end
        local RangeMenu_Count       = RangeMenu:NewEntry("Count")
        for index = 1, 4 do
            local menu_item             = RangeMenu_Count:NewEntry(index .. "-ship", function() CombatRange:SetGroupSize(index) end)
        end
        local menu_spawn            = RangeMenu:NewEntry("Spawn", function() CombatRange:SpawnAircraftBasedOnFlags() end)
        local menu_despawn          = RangeMenu:NewEntry("De-spawn", function() CombatRange:Despawn() end)

        ClientMenu:Propagate()
        self.ClientMenus[client] = ClientMenu
    end
    function CombatRange:AddTemporaryMenu()
        -- the clientset based menu doesnt work
        -- this temporary work around just sets it for bluefor
        local COALITION = coalition.side.BLUE
        local RangeMenu         = MENU_COALITION:New(COALITION, CombatRange.Name)
        local RangeMenu_Airframe    = MENU_COALITION:New(COALITION, "Airframe", RangeMenu)
        if self.Groups and #self.Groups > 0 then
            -- limit menu to 9 items, 10 is next, 11 is previous, 12 is exit
            local ParentMenu = RangeMenu_Airframe
            local PageCount = 0
            for index, unit_name in ipairs(self.Groups) do
                if PageCount == 9 then
                    ParentMenu          = MENU_COALITION:New(COALITION, "Next", ParentMenu)
                    PageCount = 0
                end
                local Airframe          = MENU_COALITION_COMMAND:New(COALITION, unit_name, ParentMenu, function() CombatRange:SetGroupType(index) end)
                PageCount = PageCount + 1
            end
        end
        local RangeMenu_Count       = MENU_COALITION:New(COALITION, "Count", RangeMenu)
        for index = 1, 4 do
            local menu_item             = MENU_COALITION_COMMAND:New(COALITION, index .. "-ship", RangeMenu_Count, function() CombatRange:SetGroupSize(index) end)
        end
        local menu_spawn            = MENU_COALITION_COMMAND:New(COALITION, "Spawn", RangeMenu, function() CombatRange:SpawnAircraftBasedOnFlags() end)
        local menu_despawn          = MENU_COALITION_COMMAND:New(COALITION, "De-spawn", RangeMenu, function() CombatRange:Despawn() end)

    end
    function CombatRange:Start()
        self:DiscoverTemplates()
        --self:CreateMenu()
        self:AddTemporaryMenu()
    end

    CombatRange:Start()

    table.insert(CombatRangeManagers, CombatRange)
end
