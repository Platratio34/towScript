local towtrucks = {} ---@type TowTruck[]
local ropes = {}

local sgvid = 0
local sgvs = {}
local function syncGetVic(source)
    local id = sgvid + 1
    sgvid = sgvid + 1
    -- print('Thing')
    TriggerClientEvent(Config.events.getVehicle, source, id)
    -- print('waiting for vic')
    while not sgvs[id] do
        Citizen.Wait(0)
    end
    -- print('got vic')
    local vic = sgvs[id]
    sgvs[id] = nil
    -- print(vic)
    return vic
end
RegisterNetEvent(Config.events.getVehicleReturn, function(id, vic)
    sgvs[id] = vic
end)

local function updateRemotes(trk, ignore)
    -- print('updating')
    for id, _ in pairs(trk.remotes) do
        if id ~= ignore then
            TriggerClientEvent(Config.events.remote.data, id, trk)
        end
    end
end

RegisterCommand(Config.commands.base, function(source, args, raw)

    if args[1] == 'remote' then

        -- print('Thinging remote')
        if args[2] == 'remove' then
            for _, trk in pairs(towtrucks) do
                if trk.holder == source then
                    trk.holder = -1
                end
            end
            TriggerClientEvent(Config.events.remote.deactivate, source)
            SendMsg(source, '~y~Removed remote for tow truck')
            return
        elseif args[2] == 'clear' then
            TriggerClientEvent(Config.events.remote.deactivate, source)
            SendMsg(source, '~y~Removed remote for tow truck')
            return
        end
        -- print('Thinging remote 2')
        local vic = syncGetVic(source)
        if vic <= 0 then
            SendMsg(source, '~r~Must be looking at a vehicle')
            return
        end
        local lId = NetworkGetEntityFromNetworkId(vic)
        if not Config.allowedCars[GetEntityModel(lId)] then
            SendMsg(source, '~r~Invalid vehicle type')
            return
        end
        if not towtrucks[vic] then
            towtrucks[vic] = {
                holder = source,
                dist = -1,
                length = 50,
                maxLength = 50,
                netid = vic,
                other = {
                    active = false,
                    netid = -1,
                    offset = vector3(0.0, 0.0, 0.0),
                    pos = vector3(0.0, 0.0, 0.0),
                },
                redirect = {
                    active = false,
                    netid = -1,
                    offset = vector3(0.0, 0.0, 0.0),
                    pos = vector3(0.0, 0.0, 0.0),
                },
                attached = false,
                retracting = false,
                vicData = Config.allowedCars[GetEntityModel(lId)],
                remotes = {}
            }
            -- print('Creating new tow truck: '..vic)
        end
        if towtrucks[vic].holder > 0 and towtrucks[vic].holder ~= source then
            SendMsg(source, '~r~Someone else has the remote')
            return
        end
        towtrucks[vic].remotes[source] = true
        TriggerClientEvent(Config.events.remote.activate, source, towtrucks[vic])
        SendMsg(source, '~g~Got remote for tow truck')
        return
    elseif args[1] == 'rope' then
        -- print('rope '..args[2])
        if args[2] == 'drop' then
            TriggerClientEvent(Config.events.rope.clear, source)
            SendMsg(source, '~y~ Rope droped')
            ropes[source] = nil
            return
        end

        local vic = syncGetVic(source)
        if vic <= 0 then
            SendMsg(source, '~r~Must be looking at a vehicle')
            return
        end

        if args[2] == 'grab' then
            if not towtrucks[vic] then
                SendMsg(source, '~r~ Must be looking at a tow truck')
                return
            end
            local point
            local vicData = towtrucks[vic].vicData
            if args[3] and args[3] ~= '' then
                point = args[3]
                if not vicData.altRope then
                    SendMsg(source, '~r~ Vehicle does not have alternent points')
                    return
                end
                if not vicData.altRope[point] then
                    SendMsg(source, '~r~ Unknown point for vehicle')
                    return
                end
                towtrucks[vic].point = point
            end
            -- local trk = towtrucks[vic]
            TriggerClientEvent(Config.events.rope.grab, source, vic)
            ropes[source] = vic
            SendMsg(source, '~g~Rope Grabed')
            return
        -- elseif args[2] == 'attach' then
        --     if not ropes[source] then
        --         SendMsg(source, '~r~Must have a rope from tow truck')
        --         return
        --     end
        --     -- print(vic)
        --     towtrucks[ropes[source]].other = {
        --         netid = vic,
        --         pos = vector3(0.0, 0.0, 0.0),
        --     }
        --     towtrucks[ropes[source]].length = -1
        --     -- print('updating')
        --     updateRemotes(towtrucks[ropes[source]])
        --     -- print('removing remote')
        --     TriggerClientEvent(Config.events.rope.clear, source)
        --     ropes[source] = nil
        --     SendMsg(source, '~g~Rope Attached')
        --     return
        elseif args[2] == 'detach' then
            for _, trk in pairs(towtrucks) do
                if trk.other.netid == vic then
                    trk.other.netid = -1
                    trk.other.active = false
                    updateRemotes(trk)
                    SendMsg(source, '~y~Vehicle Detached')
                    return
                end
            end
            if towtrucks[vic] then
                towtrucks[vic].other.netid = -1
                towtrucks[vic].other.active = false
                updateRemotes(towtrucks[vic])
                SendMsg(source, '~y~Vehicle Detached')
                return
            end
            SendMsg(source, '~r~Vehicle was not attached to anything')
            return
        elseif args[2] == 'redirect' then
            if not towtrucks[vic] then
                SendMsg(source, '~r~ Must be looking at a tow truck')
                return
            end
            TriggerClientEvent(Config.events.rope.redirect, source, vic)
            ropes[source] = vic
            return
        elseif args[2] == 'direct' then
            if not towtrucks[vic] then
                SendMsg(source, '~r~ Must be looking at a tow truck')
                return
            end
            towtrucks[vic].redirect.active = false
            updateRemotes(towtrucks[vic])
            SendMsg(source, '~g~Redirect removed')
            return
        end
        SendMsg(source, '~r~Unknown rope action')
        return
    end

    SendMsg(source, '~r~Unknown action')
end)

RegisterNetEvent(Config.events.remote.action, function(netid, action)
    -- print('action: '..action)
    if not towtrucks[netid] then print('dosnt exist: '..netid); return end
    local trk = towtrucks[netid]

    -- if action == 'retract' then
    --     print('retracting')
    --     if trk.other.netid <= 0 then print('not connected'); return end


    --     if trk.length >= trk.dist - 0.1 then
    --         trk.length = math.max(trk.length - 0.1, 2)
    --     end
    --     -- trk.length = math.min(trk.length, trk.dist)
        
    --     trk.retracting = true
    -- elseif action == 'loosen' then
    --     print('loosening')
    --     if trk.other.netid <= 0 then
    --         print('not connected'); return
    --     end
    --     trk.length = math.min(trk.length + 0.1, trk.maxLength)
    -- end
    -- updateRemotes(towtrucks[netid])
    TriggerClientEvent(Config.events.remote.action, trk.holder, action)
end)

RegisterNetEvent(Config.events.remote.data, function(src, netid, data)
    towtrucks[netid] = data
    updateRemotes(towtrucks[netid], src)
end)

RegisterNetEvent(Config.events.force, function(obj, force)
    local lid = NetworkGetEntityFromNetworkId(obj)
    -- print('forcing '..lid)
    ApplyForceToEntity(lid, 0, force, vector3(0.0, 0.0, 0.0), 0, false, true, true, false, true)
end)

RegisterNetEvent(Config.events.rope.attach, function(source, netid, offset)
    -- print(source)
    print('Attaching vehicle to rope: '..netid)
    towtrucks[ropes[source]].other = {
        active = true,
        netid = netid,
        offset = offset,
        pos = vector3(0, 0, 0),
    }
    towtrucks[ropes[source]].length = -1
    -- print('updating')
    updateRemotes(towtrucks[ropes[source]])
    -- print('removing remote')
    TriggerClientEvent(Config.events.rope.clear, source)
    ropes[source] = nil
    SendMsg(source, '~g~Rope Attached')
    return
end)

RegisterNetEvent(Config.events.rope.anchor, function(source, pos)
    -- print(source)
    towtrucks[ropes[source]].other = {
        active = true,
        netid = -1,
        offset = vector3(0, 0, 0),
        pos = pos,
    }
    towtrucks[ropes[source]].length = -1
    -- print('updating')
    updateRemotes(towtrucks[ropes[source]])
    -- print('removing remote')
    TriggerClientEvent(Config.events.rope.clear, source)
    ropes[source] = nil
    SendMsg(source, '~g~Rope Attached')
    return
end)

RegisterNetEvent(Config.events.rope.addRedirect, function(source, netid, pos)
    -- print(source)
    towtrucks[ropes[source]].redirect = {
        active = true,
        netid = netid,
        offset = pos,
        pos = pos,
    }
    towtrucks[ropes[source]].length = -1
    -- print('updating')
    updateRemotes(towtrucks[ropes[source]])
    -- print('removing remote')
    -- TriggerClientEvent(Config.events.rope.clear, source)
    ropes[source] = nil
    SendMsg(source, '~g~Redirect added')
    return
end)
-- Citizen.CreateThread(function()
--     while true do
--         for id,trk in pairs(towtrucks) do
--             prossesTruck(id)
--         end
--         Citizen.Wait(0)
--     end
-- end)

RegisterNetEvent(Config.events.force, function(trg, ent, force, offset)
    TriggerClientEvent(Config.events.force,trg, ent, force, offset)
end)