Citizen.CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/'..Config.commands.base, 'Tow truck actions', {
		{ name = 'action', help = 'remote'}
	})
end)

local isRemote = false
local remoteData = nil ---@type nil|TowTruck

RegisterNetEvent(Config.events.remote.activate, function(data)
    isRemote = true
    remoteData = data
end)
RegisterNetEvent(Config.events.remote.deactivate, function()
    isRemote = false
    remoteData = nil
end)
RegisterNetEvent(Config.events.remote.data, function(data)
    remoteData = data
end)

local retracting = false
RegisterKeyMapping("+tow.retract", "Retract tow cable", "keyboard", "NUMPAD7")
RegisterCommand("+tow.retract", function() retracting = true end)
RegisterCommand("-tow.retract", function() retracting = false end)
local loosening = false
RegisterKeyMapping("+tow.lossen", "Lossen tow cable", "keyboard", "NUMPAD4")
RegisterCommand("+tow.lossen", function() loosening = true end)
RegisterCommand("-tow.lossen", function() loosening = false end)

RegisterNetEvent(Config.events.remote.action, function(action)
    -- print('action: '..action)
    if action == 'retract' then
        retracting = true
    elseif action == 'retract.stop' then
        retracting = false
    elseif action == 'loosen' then
        loosening = true
    elseif action == 'loosen.stop' then
        loosening = false
    end
end)

local function calcForce(length, dist)
    local k = (Config.rope.E * Config.rope.A) / length
    local x = dist - length
    return math.max(k * x, 0)
end

local function attach(src, trg, bone)
    local sPos = GetEntityCoords(src)
    -- local posOff = GetOffsetFromEntityGivenWorldCoords(trg, sPos.x, sPos.y, sPos.z)
    local tPos = GetWorldPositionOfEntityBone(trg, bone)
    -- local posOff = sPos - tPos
    local rotDiff = GetEntityRotation(src) - GetEntityBoneRotation(trg, bone)
    -- print(GetEntityRotation(src), GetEntityBoneRotation(trg, bone), rotDiff)

    local vehicleHeightMin, vehicleHeightMax = GetModelDimensions(GetEntityModel(src))
    local z = 0
    if rotDiff.z > 90 or rotDiff.z < -90 then
        z = 180.0
    end
    AttachEntityToEntity(src, trg, bone, 0, 0.0, 0.05 - vehicleHeightMin.z, rotDiff.x+00.0, rotDiff.y, z, 1, 1, 1, 1, 0, 1)
    -- AttachEntityToEntity(src, trg, bone, posOff.x, posOff.y, posOff.z, rotDiff.x, rotDiff.y, rotDiff.z, false, false, true, false, 0, true)
end

local lretract, lloosen = false, false
local function prossesTruck(trk)
    ---@cast trk TowTruck
    local pid = GetPlayerServerId(PlayerId())
    if trk.holder ~= pid then
        -- print(type(trk.holder), trk.holder, type(pid), pid)
        if retracting and not lretract then
            -- print('retracting')
            TriggerServerEvent(Config.events.remote.action, trk.netid, 'retract')
        elseif lretract then
            TriggerServerEvent(Config.events.remote.action, trk.netid, 'retract.stop')
        end
        lretract = retracting
        if loosening and not lloosen then
            -- print('loosening')
            TriggerServerEvent(Config.events.remote.action, trk.netid, 'loosen')
        elseif lloosen then
            TriggerServerEvent(Config.events.remote.action, trk.netid, 'loosen.stop')
        end
        lloosen = loosening
        return
    end
    
    local isVic = trk.other.netid > 0
    if trk.other.active then
        local truck = NetworkGetEntityFromNetworkId(trk.netid)
        local car ---@type entity
        if isVic then
            print(trk.other.netid, trk.other.pos)
            car = NetworkGetEntityFromNetworkId(trk.other.netid)
            if IsEntityAttached(car) then
                trk.length = -1
            end
        end
        if (not isVic) or not (trk.attached or IsEntityAttached(car)) then
            local origin = GetWorldPositionOfEntityBone(truck, trk.vicData.originBone)
            if trk.point then
                origin = GetWorldPositionOfEntityBone(truck, trk.vicData.altRope[trk.point].bone)
                if trk.vicData.altRope[trk.point].offset then
                    local offset = GetOffsetFromEntityGivenWorldCoords(truck, origin)
                    origin = GetOffsetFromEntityInWorldCoords(truck, trk.vicData.altRope[trk.point].offset + offset)
                end
            else
                if trk.vicData.originOffset then
                    local originOff = GetOffsetFromEntityGivenWorldCoords(truck, origin)
                    origin = GetOffsetFromEntityInWorldCoords(truck, trk.vicData.originOffset + originOff)
                    -- print('adding offset: '..originPos)
                end
            end
            -- local carPos = GetEntityCoords(car)
            local endPos = trk.other.pos
            if isVic then
                endPos = GetOffsetFromEntityInWorldCoords(car, trk.other.offset)
            end
            local redirectPos = trk.redirect.pos
            if trk.redirect.active then
                if trk.redirect.netid > 0 then
                    -- print('Redirect off net:'..trk.redirect.netid)
                    local rVic = NetworkGetEntityFromNetworkId(trk.redirect.netid)
                    redirectPos = GetOffsetFromEntityInWorldCoords(rVic, trk.redirect.offset)
                end
                DrawLine(origin.x, origin.y, origin.z, redirectPos.x, redirectPos.y, redirectPos.z, 128, 128, 128, 255)
                DrawLine(redirectPos.x, redirectPos.y, redirectPos.z, endPos.x, endPos.y, endPos.z, 128, 128, 128, 255)
            else
                DrawLine(origin.x, origin.y, origin.z, endPos.x, endPos.y, endPos.z, 128, 128, 128, 255)
            end

            local diff = origin - endPos
            trk.dist = #diff
            if trk.redirect.active then
                trk.dist = #(origin - redirectPos) + #(redirectPos - endPos)
            end
            if trk.length < 0 then
                trk.length = trk.dist
                trk.length = math.max(trk.length, 0.2)
                trk.length = math.min(trk.length, trk.maxLength)
            end
            local dir = diff / trk.dist
            local invDir = dir * -1
            if trk.redirect.active then
                dir = (redirectPos - endPos) / #(redirectPos - endPos)
                invDir = (redirectPos - origin) / #(redirectPos - origin)
            end

            if retracting then
                -- print('retracting')
                local frc = calcForce(trk.length, trk.dist)
                -- if trk.length >= trk.dist - 0.02 then
                if frc < Config.towForce then
                    trk.length = math.max(trk.length - 0.01, 0.2)
                    if frc < Config.towForce/2 then
                        trk.length = math.max(trk.length - 0.01, 0.2)
                    end
                    -- print(trk.length)
                else
                    -- print('Force still need')
                end
                -- SendMsg('Reducing line length to ' .. line)
                -- trk.length = math.min(trk.length, trk.dist)
                -- ApplyForceToEntity(trk.other.serverId, 0, dir * 20, vector3(0.0, 0.0, 0.0), 0, false, true, true, false, true)
            end
            if loosening then
                trk.length = math.min(trk.length + 0.05, trk.maxLength)
                -- SendMsg('Increassing line length to '..line)
            end
            if isVic then
                if trk.vicData.attachable and IsControlJustPressed(0, 201) and trk.dist < 1 and (not trk.point) then
                    attach(car, truck, trk.vicData.attachBone)
                    -- AttachEntityBoneToEntityBone(trk.other.serverId, vic, 0, vicData.attachBone, true, true)
                    SendMsg('Attached')
                    trk.attached = true
                    trk.length = -1
                end

                SetVehicleBrake(car, false)
                SetVehicleHandbrake(car, false)
            else
                SetVehicleBrake(truck, false)
                SetVehicleHandbrake(truck, false)
            end
            if trk.length < trk.dist and trk.dist <= 50 then
                -- print('Thinging')
                -- print(dir)
                -- local force = 10
                -- if trk.retracting then
                --     force = 25
                -- end
                local force = calcForce(trk.length, trk.dist) / 20
                -- print('Appling '..math.floor(force)..' N')
                -- TriggerServerEvent(Config.events.force, remoteData.netid, force)
                local winchPosL = GetOffsetFromEntityGivenWorldCoords(truck, origin)
                if isVic then
                    if NetworkHasControlOfEntity(car) then
                        ApplyForceToEntity(car, 0, dir * force, trk.other.offset, 0, false, true, false, false, true)
                    else
                        local owner = NetworkGetEntityOwner(car)
                        TriggerServerEvent(Config.events.force, owner, trk.other.netid, dir * force, trk.other.offset)
                    end
                end
                if NetworkHasControlOfEntity(truck) then
                    ApplyForceToEntity(truck, 0, invDir * force, winchPosL, 0, false, true, false, false, true)
                else
                    local owner = NetworkGetEntityOwner(truck)
                    TriggerServerEvent(Config.events.force, owner, trk.netid, invDir * force, winchPosL)
                end
                if trk.redirect.active and trk.redirect.netid > 0 then
                    local rVic = NetworkGetEntityFromNetworkId(trk.redirect.netid)
                    local tForce = (dir * force * -1) + (invDir * force * -1)
                    if NetworkHasControlOfEntity(rVic) then
                        -- ApplyForceToEntity(rVic, 0, dir * force * -1, trk.redirect.offset, 0, false, true, false, false, true)
                        -- ApplyForceToEntity(rVic, 0, invDir * force * -1, trk.redirect.offset, 0, false, true, false, false, true)
                        ApplyForceToEntity(rVic, 0, tForce, trk.redirect.offset, 0, false, true, false, false, true)
                    else
                        local owner = NetworkGetEntityOwner(rVic)
                        TriggerServerEvent(Config.events.force, owner, trk.redirect.netid, tForce, trk.redirect.offset)
                    end
                end
                -- if trk.retracting then
                --     ApplyForceToEntity(car, 0, dir * 10, vector3(0.0, 0.0, 0.0), 0, false, true, true, false, true)
                -- end
                -- ApplyForceToEntityCenterOfMass(trk.other.serverId, 4, dir*10, false, false ,false, )
            end
            -- TriggerServerEvent(Config.events.remote.data, pid, remoteData.netid, remoteData)
        elseif isVic and IsControlJustPressed(0, 201) then
            DetachEntity(car, true, true)
            trk.attached = false
        end
    end
end

local function round(num)
    return math.floor( (num*10) + 0.5) / 10
end

Citizen.CreateThread(function()
    while true do
        if isRemote and remoteData then
            prossesTruck(remoteData)
            DrawText(0.4, 0.05, round(remoteData.dist) .. ' / ' .. round(remoteData.length), 255, 255, 255, 255)
            if remoteData.other.active then
                DrawText(0.4, 0.10, 'Numpad 7 Retract | Numpad 4 Extend', 255, 255, 255, 255)
            end
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent(Config.events.getVehicle, function(id)
    local vic = CanControl(GetPlayerPed(-1))
    -- print(vic)
    if vic <= 0 then
        TriggerServerEvent(Config.events.getVehicleReturn, id, 0)
    else
        TriggerServerEvent(Config.events.getVehicleReturn, id, NetworkGetNetworkIdFromEntity(vic))
    end
end)

RegisterNetEvent(Config.events.rope.redirect, function()
    if not remoteData then
        return
    end
    local truck = NetworkGetEntityFromNetworkId(remoteData.netid)
    local isVic = remoteData.other.netid > 0
    local car
    if isVic then car = NetworkGetEntityFromNetworkId(remoteData.other.netid) end
    while true do  
        local origin = GetWorldPositionOfEntityBone(truck, remoteData.vicData.originBone)
        if remoteData.point then
            origin = GetWorldPositionOfEntityBone(truck, remoteData.vicData.altRope[remoteData.point].bone)
            if remoteData.vicData.altRope[remoteData.point].offset then
                local offset = GetOffsetFromEntityGivenWorldCoords(truck, origin)
                origin = GetOffsetFromEntityInWorldCoords(truck, remoteData.vicData.altRope[remoteData.point].offset + offset)
            end
        else
            if remoteData.vicData.originOffset then
                local originOff = GetOffsetFromEntityGivenWorldCoords(truck, origin)
                origin = GetOffsetFromEntityInWorldCoords(truck, remoteData.vicData.originOffset + originOff)
                -- print('adding offset: '..originPos)
            end
        end
        -- local carPos = GetEntityCoords(car)
        local endPos
        if isVic then
            endPos = GetOffsetFromEntityInWorldCoords(car, remoteData.other.offset)
        else
            endPos = remoteData.other.pos
        end

        -- local lend = GetEntityCoords(GetPlayerPed(-1))
        local hit, hitC, ent = ScreenToWorld(4294967295, 0, true)
        DrawLine(origin, hitC, 128, 128, 128, 255)
        DrawLine(hitC, endPos, 128, 128, 128, 255)
        DrawSphere(hitC.x, hitC.y, hitC.z, 0.1, 0, 255, 0, 0.5)
        CursorMode()
        local isNet = false
        local nId = -1
        if hit and ent > 0 then
            print(ent)
            pcall(function()
                nId = NetworkGetNetworkIdFromEntity(ent)
                isNet = NetworkDoesNetworkIdExist(nId)
            end)
        end
        if hit and ent > 0 and isNet then
            print('hit on ent local:'..ent)
            if IsControlJustReleased(0, 237) then
                print('Adding entity redirect point local:'..ent)
                local lPoint = GetOffsetFromEntityGivenWorldCoords(ent, hitC)
                print(lPoint)
                -- TriggerServerEvent(Config.events.rope.attach, GetPlayerServerId(128), NetworkGetNetworkIdFromEntity(ent), lPoint)
                -- remoteData.redirect.active = true
                -- remoteData.redirect.netid = NetworkGetNetworkIdFromEntity(ent)
                print('net:'..NetworkGetNetworkIdFromEntity(ent))
                TriggerServerEvent(Config.events.rope.addRedirect, GetPlayerServerId(128), nId, lPoint)
                return
            end
        elseif hit then
            if IsControlJustReleased(0, 237) then
                print('Adding static redirect point')
                -- local lPoint = GetOffsetFromEntityGivenWorldCoords(ent, hitC)
                TriggerServerEvent(Config.events.rope.addRedirect, GetPlayerServerId(128), -1, hitC)
                return
            end
        end
        -- DrawLine(start, lend, 128, 128, 128, 255)
        Citizen.Wait(0)
    end
end)

RegisterNetEvent(Config.events.force, function(netid, force, offset)
    local vic = NetworkGetEntityFromNetworkId(netid)
    ApplyForceToEntity(vic, 0, force, offset, 0, false, true, false, false, true)
end)