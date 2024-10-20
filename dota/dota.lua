-- DotA implementation in MOOSE
-- DotA overview: https://www.oneesports.gg/dota2/dota-2-beginners-guide/


-- TODO:
-- * slot blocking
-- * creep upgrades
-- * slot upgrades
-- * sam defenses
-- * change colour of drawn circles on map

-- * dynamic group spawns based on unit template and pathfinding
-- makes unit changing easier
-- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Core.Astar.html


---------------------------
-- Map naming convention --
---------------------------
-- Lanes: North / Centre / South
-- Point 1 -> 6 = Left most -> Right most
--
-- N-1 -> N-6 = North Point  1 -> 6
-- C-1 -> C-6 = Centre Point 1 -> 6
-- S-1 -> S-6 = South Point  1 -> 6
--
-- 1 = Level 1 Creep
-- ..

---------------------------
--       Group names     --
---------------------------
-- Blue-S-1-1 -> Blue-S-6-1
-- Red-S-6-1 -> Red-S-6-1


---------------------------
--       Definitions     --
---------------------------
local TEAM_BLUE = "Blue"
local TEAM_RED  = "Red"
local TEAMS     = {TEAM_BLUE, TEAM_RED}
local COALITIONS = {coalition.side.BLUE, coalition.side.RED}

local LANE_NORTH  = "N"
local LANE_CENTRE = "C"
local LANE_SOUTH  = "S"
local LANES       = {LANE_NORTH, LANE_CENTRE, LANE_SOUTH}

local BASE    = "Base"
local POINT_1 = 1
local POINT_2 = 2
local POINT_3 = 3
local POINT_4 = 4
local POINT_5 = 5
local POINT_6 = 6
local POINTS  = {POINT_1, POINT_2, POINT_3, POINT_4, POINT_5, POINT_6}

local CREEP   = "Creep"
local CREEP_MIN_LEVEL = 1
local CREEP_MAX_LEVEL = 4
local CREEP_LEVELS = {}
for level=CREEP_MIN_LEVEL, CREEP_MAX_LEVEL do
    CREEP_LEVELS[level] = level
end


function point_name(lane, position)
    -- point_name(LANE_SOUTH, POINT_1) -> "S-1"
    return lane .. "-" .. position
end

function creep_group_name(team, lane, position, level)
    -- creep_group_name(TEAM_BLUE, LANE_SOUTH, POINT_1, 1) -> "Blue-S-1-1"
    return team .. "-" .. point_name(lane, position) .. "-" .. level
end
function creep_template_name(team, level)
    return team .. "-" .. CREEP .. "-" .. level
end


---------------------------
--          Zones        --
---------------------------

-- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Tasking.Task_Capture_Zone.html
-- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Functional.ZoneCaptureCoalition.html
-- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Functional.ZoneGoalCoalition.html

local OBSERVATION_INTERVAL_SECONDS = 5

local CAPTURE_ZONES = {
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(TEAM_BLUE .. "-" .. BASE), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(TEAM_RED  .. "-" .. BASE), coalition.side.RED),

    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_NORTH, POINT_1)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_NORTH, POINT_2)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_NORTH, POINT_3)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_NORTH, POINT_4)), coalition.side.RED),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_NORTH, POINT_5)), coalition.side.RED),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_NORTH, POINT_6)), coalition.side.RED),

    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_CENTRE, POINT_1)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_CENTRE, POINT_2)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_CENTRE, POINT_3)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_CENTRE, POINT_4)), coalition.side.RED),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_CENTRE, POINT_5)), coalition.side.RED),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_CENTRE, POINT_6)), coalition.side.RED),

    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_SOUTH, POINT_1)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_SOUTH, POINT_2)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_SOUTH, POINT_3)), coalition.side.BLUE),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_SOUTH, POINT_4)), coalition.side.RED),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_SOUTH, POINT_5)), coalition.side.RED),
    ZONE_CAPTURE_COALITION::New(ZONE:FindByName(point_name(LANE_SOUTH, POINT_6)), coalition.side.RED),
}

-- register our callbacks for our zone
for _, zone in ipairs(CAPTURE_ZONES) do
    function zone:OnEnterGuarded(From, Event, To)
        -- on capture, set the smoke to the new faction and print a message
        if From ~= To then
            local Coalition = self:GetCoalition()
            self:E({Coalition = Coalition})
            if Coalition == coalition.side.BLUE then
                ZoneCaptureCoalition:Smoke(SMOKECOLOR.Blue)
                US_CC:MessageTypeToCoalition(string.format("We have taken %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
                RU_CC:MessageTypeToCoalition(string.format("The enemy has taken %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
            else
                ZoneCaptureCoalition:Smoke(SMOKECOLOR.Red)
                RU_CC:MessageTypeToCoalition(string.format("We have taken %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
                US_CC:MessageTypeToCoalition(string.format("The enemy has taken %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
            end
        end
    end

    function zone:OnEnterAttacked()
        -- on attacked, set the smoke to white and print a message
        ZoneCaptureCoalition:Smoke(SMOKECOLOR.White)
        local Coalition = self:GetCoalition()
        self:E({Coalition = Coalition})
        if Coalition == coalition.side.BLUE then
            US_CC:MessageTypeToCoalition(string.format("The enemy is attacking %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
            RU_CC:MessageTypeToCoalition(string.format("We are attacking %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
        else
            RU_CC:MessageTypeToCoalition(string.format("The enemy is attacking %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
            US_CC:MessageTypeToCoalition(string.format("We are attacking %s", ZoneCaptureCoalition:GetZoneName()), MESSAGE.Type.Information)
        end
    end

    function zone:OnEnterEmpty()
        -- replace the smoke with the current coalition's smoke
        local Coalition = self:GetCoalition()
        if Coalition == coalition.side.BLUE then
            ZoneCaptureCoalition:Smoke(SMOKECOLOR.Blue)
        else
            ZoneCaptureCoalition:Smoke(SMOKECOLOR.Red)
        end
    end

    -- start monitoring zones Ns after start, and then every Ms
    zone:Start(OBSERVATION_INTERVAL_SECONDS, OBSERVATION_INTERVAL_SECONDS)
end

-- Connections between zones
-- specifies which point is next for each team
local ZONE_CONNECTIONS = {
    -- LANE_NORTH
    [ZONE:FindByName(point_name(LANE_NORTH, POINT_1))]  = {[TEAM_RED] = ZONE:FindByName(TEAM_BLUE .. "-" .. BASE),         [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_NORTH, POINT_2))},
    [ZONE:FindByName(point_name(LANE_NORTH, POINT_2))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_NORTH, POINT_1)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_NORTH, POINT_3))},
    [ZONE:FindByName(point_name(LANE_NORTH, POINT_3))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_NORTH, POINT_2)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_NORTH, POINT_4))},
    [ZONE:FindByName(point_name(LANE_NORTH, POINT_4))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_NORTH, POINT_3)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_NORTH, POINT_5))},
    [ZONE:FindByName(point_name(LANE_NORTH, POINT_5))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_NORTH, POINT_4)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_NORTH, POINT_6))},
    [ZONE:FindByName(point_name(LANE_NORTH, POINT_6))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_NORTH, POINT_5)),  [TEAM_BLUE] = ZONE:FindByName(TEAM_RED .. "-" .. BASE)},
    -- LANE_CENTRE
    [ZONE:FindByName(point_name(LANE_CENTRE, POINT_1))] = {[TEAM_RED] = ZONE:FindByName(TEAM_BLUE .. "-" .. BASE),         [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_2))},
    [ZONE:FindByName(point_name(LANE_CENTRE, POINT_2))] = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_1)), [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_3))},
    [ZONE:FindByName(point_name(LANE_CENTRE, POINT_3))] = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_2)), [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_4))},
    [ZONE:FindByName(point_name(LANE_CENTRE, POINT_4))] = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_3)), [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_5))},
    [ZONE:FindByName(point_name(LANE_CENTRE, POINT_5))] = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_4)), [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_6))},
    [ZONE:FindByName(point_name(LANE_CENTRE, POINT_6))] = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_5)), [TEAM_BLUE] = ZONE:FindByName(TEAM_RED .. "-" .. BASE)},
    -- LANE_SOUTH
    [ZONE:FindByName(point_name(LANE_SOUTH, POINT_1))]  = {[TEAM_RED] = ZONE:FindByName(TEAM_BLUE .. "-" .. BASE),         [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_2))},
    [ZONE:FindByName(point_name(LANE_SOUTH, POINT_2))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_1)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_3))},
    [ZONE:FindByName(point_name(LANE_SOUTH, POINT_3))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_2)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_4))},
    [ZONE:FindByName(point_name(LANE_SOUTH, POINT_4))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_3)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_5))},
    [ZONE:FindByName(point_name(LANE_SOUTH, POINT_5))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_4)),  [TEAM_BLUE] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_6))},
    [ZONE:FindByName(point_name(LANE_SOUTH, POINT_6))]  = {[TEAM_RED] = ZONE:FindByName(point_name(LANE_SOUTH, POINT_5)),  [TEAM_BLUE] = ZONE:FindByName(TEAM_RED .. "-" .. BASE)},
    -- bases
    [ZONE:FindByName(TEAM_RED .. "-" .. BASE)]          = {[TEAM_RED] = nil,                                               [TEAM_BLUE] = nil},
    [ZONE:FindByName(TEAM_BLUE .. "-" .. BASE)]         = {[TEAM_RED] = nil,                                               [TEAM_BLUE] = nil},
}


function route_from_zone(team, zone)
    -- generate a list of zones from the current zone to the last
    local zones = {}

    while true
        local current_zone = ZONE_CONNECTIONS[team][zone]
        if current_zone == nil then break end

        table.insert(zones, current_zone)
    end
    return zones
end


---------------------------
--    COALITION State    --
---------------------------
local state = {}
local SCORE = "score"
local SCORE_DELTA = "score_delta"
local CREEP_LEVEL = "creep_level"

for _, team in ipairs({TEAM_BLUE, TEAM_RED}) do
    state[team] = {
        [SCORE] = 0,
        [SCORE_DELTA] = 0,
        [CREEP_LEVEL] = CREEP_MIN_LEVEL,
    }
end

function team_score(team)
    return state[team][SCORE]
end
function team_score_delta(team)
    return state[team][SCORE_DELTA]
end
function team_creep_level(team)
    return state[team][CREEP_LEVEL]
end
function team_creep_increment_level(team)
    if state[team][CREEP_LEVEL] < CREEP_MAX_LEVEL then
        state[team][CREEP_LEVEL] = state[team][CREEP_LEVEL] + 1
    end
end
function team_add_points(team, points)
    state[team][SCORE] = state[team][SCORE] + points
    state[team][SCORE_DELTA] = state[team][SCORE_DELTA] + points
end
function team_sufficient_points(team, points)
    return state[team][SCORE] > points
end
function team_subtract_points(team, points)
    state[team][SCORE] = state[team][SCORE] - points
end
function team_clear_score_delta(team)
    state[team][SCORE_DELTA] = 0
end


---------------------------
--         Score         --
---------------------------

local INTERVAL_PRINT_SCORE = 20

function print_points()
    -- print the score, score delta, and then clear the delta
    local message = "Blue: " .. team_score(TEAM_BLUE) .. " (+" .. team_score_delta(TEAM_BLUE) .. ")\n" ..
                    "Red:  " .. team_score(TEAM_RED)  .. " (+" .. team_score_delta(TEAM_RED)  .. ")"
    MESSAGE:New(message, 10):ToAll()

    team_clear_score_delta(TEAM_BLUE)
    team_clear_score_delta(TEAM_RED)
end

SCHEDULER:New(nil, print_points, {}, INTERVAL_PRINT_SCORE,        INTERVAL_PRINT_SCORE)


---------------------------
--        Creeps         --
---------------------------
local INTERVAL_CREEP_SPAWN = 20

-- moose is dumb in that it:
-- * wants you to use scheduled spawners, instead of using the scheduler it provides and spawn yourself
-- * wants you to take a group, create a spawn group, and then spawn from that
-- * will destroy any units from a spawn group if you re-create one with the same name
-- so make moose happy and just make all the bloody spawn groups on startup
-- pre-create our spawn groups
local CREEP_SPAWNERS = {}

for _, team in ipairs(TEAMS) do
    for _, level in ipairs(CREEP_LEVELS) do
        local template_name = creep_template_name(team, level)
        CREEP_SPAWNERS[team][level] = SPAWN:NewWithAlias(template_name, template_name)
    end
end

function zone_route_to_waypoints(zones)
    local waypoints = {}
    
    for _, zone in ipairs(zones) do
        local point = zone:GetPointVec2()
        table.insert(waypoints, { x = point.x, y = 0, z = point.z })
    end
    return waypoints
end


function spawn_creeps_at_zone(zone)
    -- spawn and route to another zone!!
    ------ https://forum.dcs.world/topic/173928-dynamic-spawning-and-routing-in-moose/?do=findComment&comment=3432819

    local Coalition = zone:GetCoalition()
    local team = (Coalition == coalition.side.BLUE and TEAM_BLUE or TEAM_RED)
    local level = team_creep_level(team)

    local spawner = CREEP_SPAWNERS[team][level]
    local randomize_point = false
    local speed_kmh = 50
    local formation = "Vee"

    local route = zone_route_to_waypoints(route_from_zone(team, zone))

    local group = spawner
        :SpawnInZone(zone)
        :OnSpawnGroup(function(spawn_group)
            function spawn_group:OnEventDead(event)
                -- TODO: determine who got the hit and give their team credit
                --event.IniUnit:MessageToAll("I just got killed and I am part of " .. event.IniGroupName, 15, "Alert!")
            end)

            spawn_group:SetTask({id = "Task", params={route=route}})
        end)
        :Spawn()

    return group
end

function spawn_creeps()
    MESSAGE:New("Spawning Creeps", 5):ToAll()

    for _, zone in ipairs(CAPTURE_ZONES) do
        spawn_creeps_at_zone(zone)
    end
end

SCHEDULER:New(nil, spawn_creeps, {}, INTERVAL_CREEP_SPAWN, INTERVAL_CREEP_SPAWN)


---------------------------
--         Menu          --
---------------------------

local AIRFRAME_UNLOCKS = {
    {name="AJS-37",      cost=100,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="AV-8B",       cost=150,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="A-4",         cost= 60,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="A-10",        cost=200,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="F-4",         cost= 80,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="F-5",         cost= 40,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="F-14",        cost=100,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="F-15C",       cost=150,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="F-15E",       cost=300,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="F-16",        cost=180,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="F/A-18",      cost=200,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="Su-27"        cost=200,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="MiG-21"       cost= 60,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="Mirage F1",   cost= 60,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="Mirage 2000", cost=300,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="AH-64D",      cost=100,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="OH-58",       cost= 40,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="Mi-8"         cost= 60,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="Mi-24",       cost= 80,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="Ka-52",       cost=120,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="UH-1H",       cost= 40,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
    {name="SA342",       cost= 80,    [coalition.side.BLUE]=nil, [coalition.side.RED]=nil},
}

function unlock_and_remove_menu(team, airframe)
    -- check the team has enough points
    local cost = airframe.cost

    if team_sufficient_points(team, cost) then
        -- subtract points
        team_subtract_points(team, cost)

        -- TODO: unlock the spawns

        -- remove the menu item
        airframe[team]:Remove()
        airframe[team] = nil
    end
end

function setup_radio_menu_spawn(team)
    spawn_menu          = MENU_COALITION:New(team, "Spawn Unlocks")

    for _, airframe in ipairs(AIRFRAME_UNLOCKS) do
        airframe[team] = MENU_COALITION_COMMAND:New(team, "Unlock " .. airframe.name .. "    [" .. airframe.cost .. "]", spawn_menu, function unlock_and_remove_menu(team, airframe) end)
    end
end


local CREEP_COST = {
    [1]    = 100,
    [2]    = 200,
    [3]    = 300,
    [4]    = 400,
}
local CREEP_MENUS = {
    [coalition.side.BLUE] = nil,
    [coalition.side.RED]  = nil,
}

function team_creep_increment_level(team)
end

function creep_upgrade_text(team)
    return "Tier " .. team_creep_level(team) .. " upgrade [" .. CREEP_COST[team_creep_level(team)] .. "]"
end

function upgrade_creeps(team)
    local cost = CREEP_COST[team_creep_level(team)]

    if team_sufficient_points(team, cost) then
        -- subtract points
        team_subtract_points(team, cost)

        -- remove tier N upgrade item
        CREEP_MENUS[team]:Remove()

        -- add tier N+1 upgrade menu item
        -- dont add menu item if we've hit max level
        if team_creep_increment_level(team) then
            CREEP_MENUS[team] = MENU_COALITION_COMMAND:New(team, creep_upgrade_text(team), creep_menu, function upgrade_creeps(team) end)
        end
end

function setup_radio_menu_creeps(team)
    local creep_menu  = MENU_COALITION:New(team, "Creep Upgrades")
    CREEP_MENUS[team] = MENU_COALITION_COMMAND:New(team, creep_upgrade_text(team), creep_menu, function upgrade_creeps(team) end)
end

function setup_radio_menu()
    for _, team in ipairs(COALITIONS) do
        setup_radio_menu_creeps(team)
        setup_radio_menu_spawn(team)
    end
end


---------------------------
--   Victory Conditions  --
---------------------------

-- TODO --
















--[[

-- OLD

---------------------------
--        Creeps         --
---------------------------
local interval_creep_spawn_timer = 20


-- moose is dumb in that it:
-- * wants you to use scheduled spawners, instead of using the scheduler it provides and spawn yourself
-- * wants you to take a group, create a spawn group, and then spawn from that
-- * will destroy any units from a spawn group if you re-create one with the same name
-- so make moose happy and just make all the bloody spawn groups on startup
-- pre-create our spawn groups
local creep_spawn_groups = {}

function create_creep_spawn_group(team, lane, position, level)
    local group_name = creep_group_name(team, lane, position, level)
    creep_spawn_groups[group_name] = SPAWN:NewWithAlias(group_name, "Creep-" .. group_name)
end

for _, team in ipairs(COALITIONS) do
    for _, lane in ipairs(LANES) do
        for _, point in ipairs(POINTS) do
            for level=CREEP_MIN_LEVEL,CREEP_MAX_LEVEL do
                create_creep_spawn_group(team, lane, point, level)
            end
        end
    end
end






function spawn_group(group_name)
    --local spawn_object = SPAWN:NewWithAlias(group_name, "Creep-" .. group_name)
    local spawn_object = creep_spawn_groups[group_name]
    local group = spawn_object:Spawn()

    group:HandleEvent(EVENTS.Dead)

    function group:OnEventDead(EventData)
        -- TODO: determine who got the hit and give their team credit
        --EventData.IniUnit:MessageToAll("I just got killed and I am part of " .. EventData.IniGroupName, 15, "Alert!")
    end

    return group
end


function spawn_creep_group(team, lane, position, level)
    local group_name = creep_group_name(team, lane, position, level)
    local group = spawn_group(group_name)
end

function spawn_creeps()
    MESSAGE:New("Spawning Creeps", 5):ToAll()

    spawn_creep_group(TEAM_BLUE, LANE_SOUTH, POINT_1, CREEP_1)
    spawn_creep_group(TEAM_BLUE, LANE_SOUTH, POINT_2, CREEP_1)
    spawn_creep_group(TEAM_BLUE, LANE_SOUTH, POINT_3, CREEP_1)

    spawn_creep_group(TEAM_RED, LANE_SOUTH, POINT_6, CREEP_1)
    spawn_creep_group(TEAM_RED, LANE_SOUTH, POINT_5, CREEP_1)
    spawn_creep_group(TEAM_RED, LANE_SOUTH, POINT_4, CREEP_1)
end


SCHEDULER:New(nil, spawn_creeps, {}, interval_creep_spawn_timer, interval_creep_spawn_timer)



]]--









--[[
ChatGPT answers






-- Define your zones
local zones = {
    ZONE:FindByName("Zone1"),
    ZONE:FindByName("Zone2"),
    ZONE:FindByName("Zone3"),
    ZONE:FindByName("Zone4")
}

-- Function to create a route from a series of zones
local function createRoute(zones)
    local waypoints = {}
    
    for _, zone in ipairs(zones) do
        local point = zone:GetPointVec2()
        table.insert(waypoints, { x = point.x, y = 0, z = point.z })
    end

    return waypoints
end

-- Function to start routing a unit through the zones
local function routeUnit(unit)
    local route = createRoute(zones)
    unit:SetTask({ 
        id = "Task", 
        params = {
            route = route
        }
    })
end

-- Optional: Define a function to handle the unit reaching a waypoint
local function onWaypointReached(unit, waypointIndex)
    -- Handle additional logic if needed
    -- For example, you might want to perform actions when the unit reaches a specific waypoint
end

-- Define the unit and start routing
local unit = UNIT:FindByName("MyUnit")
routeUnit(unit)

-- Example event handler for waypoint reaching
function onEventWaypointReached(event)
    if event.id == world.event.S_EVENT_UNIT_LAND then
        local unit = event.unit
        local waypointIndex = event.payload -- Assuming payload contains the waypoint index
        onWaypointReached(unit, waypointIndex)
    end
end

world.addEventHandler(onEventWaypointReached)












-- Define the group name
local groupName = "MyGroup"

-- Find the group by name
local group = Group.getByName(groupName)

-- Function to check if the group has reached the last waypoint
local function hasReachedLastWaypoint(group)
    if group then
        local groupController = group:getController()
        local waypoint = groupController:getTask(1):getWaypoint()
        if waypoint then
            local lastWaypoint = groupController:getTask(1):getWaypoints()[#groupController:getTask(1):getWaypoints()]
            local groupPosition = group:getUnit(1):getPoint()
            local lastWaypointPosition = lastWaypoint.point
            
            -- Define a tolerance value to account for small positional errors
            local tolerance = 100 -- meters

            local distance = math.sqrt((groupPosition.x - lastWaypointPosition.x)^2 + (groupPosition.z - lastWaypointPosition.z)^2)

            return distance <= tolerance
        end
    end
    return false
end

-- Function to be called periodically to check the condition
local function checkGroupPosition()
    if hasReachedLastWaypoint(group) then
        trigger.action.outText("Group has reached the last waypoint!", 10)
    end
end

-- Schedule the check function to run periodically
timer.scheduleFunction(checkGroupPosition, nil, timer.getTime() + 10)











-- Define the initial waypoints for the unit
local function createInitialRoute()
    return {
        [1] = { x = 1000, y = 0, z = 1000 },
        [2] = { x = 2000, y = 0, z = 2000 },
    }
end

-- Define the new waypoints for the unit
local function createNewRoute()
    return {
        [1] = { x = 3000, y = 0, z = 3000 },
        [2] = { x = 4000, y = 0, z = 4000 },
    }
end

-- Function to set a new route for the unit
local function setNewRoute(unit)
    local newRoute = createNewRoute()
    unit:Route(newRoute)
end

-- Function to check if the unit has reached the last waypoint
local function onWaypointReached(unit, waypointIndex)
    local route = unit:getRoute()
    if waypointIndex == #route then
        -- The unit has reached the last waypoint of the current route
        setNewRoute(unit)
    end
end

-- Create the unit and assign the initial route
local unit = UNIT:FindByName("MyUnit")
local initialRoute = createInitialRoute()
unit:Route(initialRoute)

-- Register an event handler to detect waypoint arrival
function onEventWaypointReached(event)
    if event.id == world.event.S_EVENT_UNIT_ROCKET then
        local unit = event.unit
        local waypointIndex = event.payload -- Assuming payload is the waypoint index
        onWaypointReached(unit, waypointIndex)
    end
end

world.addEventHandler(onEventWaypointReached)



]]--





