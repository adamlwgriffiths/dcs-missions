local creep_spawn_timer = 60
local clean_junk_timer = 5

local function print_all(message)
    local msg = {}
    msg.text = message
    msg.displayTime = 5
    msg.msgFor = {coa = {'all'}}
    mist.message.add(msg)
end

function spawn_creep()
    print_all("Spawning creeps")

    mist.cloneGroup('Blue-Creep-1', true)
    mist.cloneGroup('Red-Creep-1', true)
end

mist.scheduleFunction(spawn_creep, nil, timer.getTime(), creep_spawn_timer)



local function cleanup()
    print_all("Cleaning junk")

    local zone = trigger.misc.getZone('Junk-1')
    zone.point.y = land.getHeight({x = zone.point.x, y = zone.point.z})

    local volume = {
        id = world.VolumeType.SPHERE,
        params = {
            point = zone.point,
            radius = zone.radius
        }
    }
    world.removeJunk(volume)

    -- look for fire effects
    local object_iterator = function(obj, val)
	print_all("Found object " .. obj:getName())
        obj:destroy()
        return false
    end
    world.searchObjects(Object.Category.STATIC, volume, object_iterator)
    world.searchObjects(Object.Category.SCENERY, volume, object_iterator)
    world.searchObjects(Object.Category.Cargo, volume, object_iterator)
    world.searchObjects(Object.Category.WEAPON, volume, object_iterator)

    local unit_iterator = function(obj, val)
	print_all("Found object " .. obj:getName())
        if obj:getLife() < 0 then
            obj:destroy()
        end
        return false
    end
    world.searchObjects(Object.Category.UNIT, volume, unit_iterator)
end

--mist.scheduleFunction(cleanup, nil, timer.getTime(), clean_junk_timer)


local function unit_dead(event)
    --if event.id == world.event.S_EVENT_KILL then
    if event.id == world.event.S_EVENT_UNIT_LOST then
        if event.initiator ~= null then
            --if event.initiator:getLife() <= 1 then
            --we can get spurious events with nulls and no name
            if event.initiator:getName():len() then
                print_all(event.initiator:getName() .. " killed!")
                event.initiator:destroy()

                --Unit.destroy(event.initiator)

                --local unit = UNIT:FindByName(event.initiator:getName())
                --unit:Destroy()
            end
        end
    end
end

mist.addEventHandler(unit_dead)



----- MOOSE

EventHandler1 = EVENTHANDLER:New()
EventHandler1:HandleEvent(EVENTS.Hit)
EventHandler1:HandleEvent(EVENTS.UnitLost)

function EventHandler1:OnEventHit( EventData )
    --print_all("OnEventHit")
    --MESSAGE:ToAll("OnEventHit")
end

function EventHandler1:OnEventUnitLost(EventData)
    print_all("OnEventUnitLost")
    --MESSAGE:ToAll("OnEventUnitLost")
end



UnitSetRed = SET_UNIT:New():FilterPrefixes("Red-"):FilterStart()
UnitSetRed:HandleEvent(EVENTS.Hit)

function UnitSetRed:OnEventHit(EventData)
    --print_all("UnitSetRed:OnEventHit")
    --MESSAGE:ToAll("UnitSetRed:OnEventHit")
    --MESSAGE:ToAll("Red unit hit" .. EventData.IniUnit:GetName(), 15, "Alert!" )
end


UnitSetBlue = SET_UNIT:New():FilterPrefixes("Blue-"):FilterStart()
UnitSetBlue:HandleEvent(EVENTS.Hit)

function UnitSetBlue:OnEventHit(EventData)
    --print_all("UnitSetBlue:OnEventHit")
    --MESSAGE:ToAll("UnitSetBlue:OnEventHit")
    --MESSAGE:ToAll("Blue unit hit" .. EventData.IniUnit:GetName(), 15, "Alert!" )
end

MESSAGE:ToAll("MESSAGE:ToAll")