-- DotA implementation in MOOSE
-- DotA overview: https://www.oneesports.gg/dota2/dota-2-beginners-guide/


-- TODO:
-- * point control
-- * slot blocking
-- * creep upgrades
-- * slot upgrades
-- * point smoke colour (red/blue smoke) -- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Core.Point.html
-- * sam defenses


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
local TEAM_RED = "Red"
local TEAMS = {TEAM_BLUE, TEAM_RED}

local LANE_NORTH = "N"
local LANE_CENTRE = "C"
local LANE_SOUTH = "S"
local LANES = {LANE_NORTH, LANE_CENTRE, LANE_SOUTH}

local POINT_0 = "0" -- blue base
local POINT_1 = "1"
local POINT_2 = "2"
local POINT_3 = "3"
local POINT_4 = "4"
local POINT_5 = "5"
local POINT_6 = "6"
local POINT_7 = "7" -- red base
local POINTS = {POINT_0, POINT_1, POINT_2, POINT_3, POINT_4, POINT_5, POINT_6, POINT_7}

local CREEP_1 = "1"
local CREEP_2 = "2"
local CREEP_3 = "3"
local CREEP_4 = "4"
local CREEPS = {CREEP_1, CREEP_2, CREEP_3, CREEP_4}

local BASE = "Base"
local FARP = "FARP"


function point_name(lane, position)
    -- point_name(LANE_SOUTH, POINT_1) -> "S-1"
    return lane .. "-" .. position
end

function creep_group_name(team, lane, position, level)
    -- creep_group_name(TEAM_BLUE, LANE_SOUTH, POINT_1, CREEP_1) -> "Blue-S-1-1"
    return team .. "-" .. point_name(lane, position) .. "-" .. level
end


local ZONES = {
    [LANE_NORTH] = {
        [POINT_0] = ZONE:FindByName(TEAM_BLUE .. "-" .. BASE),
        [POINT_1] = ZONE:FindByName(point_name(LANE_NORTH, POINT_1)),
        [POINT_2] = ZONE:FindByName(point_name(LANE_NORTH, POINT_2)),
        [POINT_3] = ZONE:FindByName(point_name(LANE_NORTH, POINT_3)),
        [POINT_4] = ZONE:FindByName(point_name(LANE_NORTH, POINT_4)),
        [POINT_5] = ZONE:FindByName(point_name(LANE_NORTH, POINT_5)),
        [POINT_6] = ZONE:FindByName(point_name(LANE_NORTH, POINT_6)),
        [POINT_7] = ZONE:FindByName(TEAM_RED .. "-" .. BASE),
    },
    [LANE_CENTRE] = {
        [POINT_0] = ZONE:FindByName(TEAM_BLUE .. "-" .. BASE),
        [POINT_1] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_1)),
        [POINT_2] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_2)),
        [POINT_3] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_3)),
        [POINT_4] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_4)),
        [POINT_5] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_5)),
        [POINT_6] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_6)),
        [POINT_7] = ZONE:FindByName(TEAM_RED .. "-" .. BASE),
    },
    [LANE_CENTRE] = {
        [POINT_0] = ZONE:FindByName(TEAM_BLUE .. "-" .. BASE),
        [POINT_1] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_1)),
        [POINT_2] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_2)),
        [POINT_3] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_3)),
        [POINT_4] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_4)),
        [POINT_5] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_5)),
        [POINT_6] = ZONE:FindByName(point_name(LANE_CENTRE, POINT_6)),
        [POINT_7] = ZONE:FindByName(TEAM_RED .. "-" .. BASE),
    },
}

for _, lane in ipairs(POINTS) do
    ZONES[lane] = {}
    for _, point in ipairs(POINTS) do
        if point == POINT_0 then
            ZONES[lane][point] = ZONE:FindByName(TEAM_BLUE .. "-" .. BASE)
        elseif point == POINT_7 then
            ZONES[lane][point] = ZONE:FindByName(TEAM_RED .. "-" .. BASE)
        else
            ZONES[lane][point] = ZONE:FindByName(point_name(lane, point))
        end
    end
end


-- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Core.Point.html##(COORDINATE).GetClosestPointToRoad
-- https://flightcontrol-master.github.io/MOOSE_DOCS/Documentation/Core.Point.html##(COORDINATE).GetPathOnRoad
-- COORDINATE:GetClosestPointToRoad(Railroad)
--[[ local ROUTES = {
    [LANE_SOUTH] = {
        [POINT_0] = {
            [POINT_1] = ZONES[LANE_SOUTH][POINT_0]:GetVec2():GetPathOnRoad(ZONES[LANE_SOUTH][POINT_1]:GetVec2(), true)
        },
        [POINT_1] = {
            [POINT_0] = [],
            [POINT_2] = [],
        },
        [POINT_2] = {
            [POINT_1] = [],
            [POINT_3] = [],
        },
        [POINT_3] = {
            [POINT_2] = [],
            [POINT_4] = [],
        },
        [POINT_4] = {
            [POINT_3] = [],
            [POINT_5] = [],
        },
        [POINT_5] = {
            [POINT_4] = [],
            [POINT_6] = [],
        },
        [POINT_6] = {
            [POINT_5] = [],
            [POINT_7] = [],
        },
        [POINT_7] = {
            [POINT_6] = [],
        },
    },
} ]]--


---------------------------
--      Global State     --
---------------------------
local score = {[TEAM_BLUE] = 0, [TEAM_RED] = 0}
local score_delta = {[TEAM_BLUE] = 0, [TEAM_RED] = 0}  -- stores points accumulated since the last message

-- timers
--local interval_creep_spawn_timer = 120
--local interval_score_print = 30
local interval_creep_spawn_timer = 20
local interval_score_print = 20


---------------------------
--        Routes         --
---------------------------


function create_route(from, to)
    local waypoints = {}

end



---------------------------
--       Spawning        --
---------------------------

-- moose is dumb in that it:
-- * wants you to use scheduled spawners, instead of using the scheduler it provides and spawn functions yourself
-- * wants you to take a group, create a spawn group, and then spawn from that
-- * will destroy any units from a spawn group if you re-create one with the same name
-- so make moose happy and just make all the bloody spawn groups on startup
-- pre-create our spawn groups
local creep_spawn_groups = {}

function create_creep_spawn_group(team, lane, position, level)
    local group_name = creep_group_name(team, lane, position, level)
    creep_spawn_groups[group_name] = SPAWN:NewWithAlias(group_name, "Creep-" .. group_name)
end

create_creep_spawn_group(TEAM_BLUE, LANE_SOUTH, POINT_1, CREEP_1)
create_creep_spawn_group(TEAM_BLUE, LANE_SOUTH, POINT_2, CREEP_1)
create_creep_spawn_group(TEAM_BLUE, LANE_SOUTH, POINT_3, CREEP_1)
create_creep_spawn_group(TEAM_RED, LANE_SOUTH, POINT_6, CREEP_1)
create_creep_spawn_group(TEAM_RED, LANE_SOUTH, POINT_5, CREEP_1)
create_creep_spawn_group(TEAM_RED, LANE_SOUTH, POINT_4, CREEP_1)






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

function print_points()
    -- print the score, score delta, and then clear the delta
    local message = "Blue: " .. score[TEAM_BLUE] .. ", Red: " .. score[TEAM_RED] .. "\n" ..
                    "Blue: +" .. score_delta[TEAM_BLUE] .. ", Red: +" .. score_delta[TEAM_RED]
    MESSAGE:New(message, 10):ToAll()

    score_delta[TEAM_BLUE] = 0
    score_delta[TEAM_RED] = 0
end


---------------------------
--      Schedules        --
---------------------------
SCHEDULER:New(nil, spawn_creeps, {}, interval_creep_spawn_timer, interval_creep_spawn_timer)
SCHEDULER:New(nil, print_points, {}, interval_score_print,       interval_score_print)
