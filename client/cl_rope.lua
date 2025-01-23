local ropeStart = -1

RegisterNetEvent(Config.events.rope.grab, function(netId)
    ropeStart = NetworkGetEntityFromNetworkId(netId)
end)
RegisterNetEvent(Config.events.rope.clear, function()
    ropeStart = -1
end)


function CursorMode()
    DisableControlAction(0, 24, true) -- disable attack
    DisableControlAction(0, 25, true) -- disable aim
    DisableControlAction(0, 47, true) -- disable weapon
    DisableControlAction(0, 58, true) -- disable weapon
    DisableControlAction(0, 263, true) -- disable melee
    DisableControlAction(0, 264, true) -- disable melee
    DisableControlAction(0, 257, true) -- disable melee
    DisableControlAction(0, 140, true) -- disable melee
    DisableControlAction(0, 141, true) -- disable melee
    DisableControlAction(0, 142, true) -- disable melee
    DisableControlAction(0, 143, true) -- disable melee
end

Citizen.CreateThread(function()
    while true do
        if ropeStart > 0 then
            local start = GetEntityCoords(ropeStart)
            -- local lend = GetEntityCoords(GetPlayerPed(-1))
            local hit, hitC, ent = ScreenToWorld(4294967295, ropeStart, true)
            if hit then
                DrawLine(start, hitC, 128, 128, 128, 255)
                DrawSphere(hitC.x, hitC.y, hitC.z, 0.1, 0, 255, 0, 0.5)
                CursorMode()
                if IsControlJustReleased(0, 237) then
                    pcall(function()
                        nId = NetworkGetNetworkIdFromEntity(ent)
                        isNet = NetworkDoesNetworkIdExist(nId)
                    end)
                    if isNet then
                        local lPoint = GetOffsetFromEntityGivenWorldCoords(ent, hitC)
                        TriggerServerEvent(Config.events.rope.attach, GetPlayerServerId(128), nId, lPoint)
                    else
                        TriggerServerEvent(Config.events.rope.anchor, GetPlayerServerId(128), hitC)
                    end
                end
            elseif hit then
                DrawSphere(hitC.x, hitC.y, hitC.z, 0.1, 255, 0, 0, 0.5)
            end
            -- DrawLine(start, lend, 128, 128, 128, 255)
        end
        Citizen.Wait(0)
    end
end)