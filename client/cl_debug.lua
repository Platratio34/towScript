local vic = -1

Citizen.CreateThread(function()
    while true do
        if vic > 0 then
            for i = 0, GetEntityBoneCount(vic) do
                local pos = GetWorldPositionOfEntityBone(vic, i)
                Draw3dText(pos, i)
            end
        end
        
        if Config.allowedCars[GetEntityModel(vic)] then
            local data = Config.allowedCars[GetEntityModel(vic)]
            local originPos = GetWorldPositionOfEntityBone(vic, data.originBone)
            if data.originOffset then
                local originOff = GetOffsetFromEntityGivenWorldCoords(vic, originPos)
                originPos = GetOffsetFromEntityInWorldCoords(vic, data.originOffset + originOff)
                -- print('adding offset: '..originPos)
            end
            -- print('origin pos: '..originPos)
            DrawBoxAt(originPos, 0.1, 0, 255, 0, 0.5)
            if data.attachable then
                local attachPos = GetWorldPositionOfEntityBone(vic, data.attachBone)
                -- print('attach pos: ' .. attachPos)
                DrawBoxAt(attachPos, 0.25, 0, 0, 255, 0.5)
            end
            
            if data.altRope then
                for name, rope in pairs(data.altRope) do
                    -- print('rendering '..name)
                    local pos = GetWorldPositionOfEntityBone(vic, rope.bone)
                    if rope.offset then
                        local offset = GetOffsetFromEntityGivenWorldCoords(vic, pos)
                        pos = GetOffsetFromEntityInWorldCoords(vic, rope.offset + offset)
                    end
                    DrawBoxAt(pos, 0.1, 0, 255, 255, 0.5)
                    Draw3dText(pos, name)
                end
            end
        end
        Citizen.Wait(0)
    end
end)

RegisterCommand('towdebug', function(source, args, raw)
    if args[1] == 'clear' then
        vic = -1
        SendMsg('~y~Debug vehicle cleard')
        return
    end
    local pPed = GetPlayerPed(-1)
    local v = GetVehiclePedIsIn(pPed)
    if v <= 0 then
        SendMsg('~r~Not in a vehicle')
        return
    end
    vic = v
    SendMsg('~g~Debug Vehicle Set')
end)