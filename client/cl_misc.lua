function SendMsg(msg)
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        template = '<div>{0}^r: {1}</div>',
        args = { 'Tow', msg },
    })
end

function PrintTable(tbl)
    for k,v in pairs(tbl) do
        print(k..': '..v)
    end
end

function DrawText(x, y, text, r, g, b, a)
    -- local posX = 0.5
    -- local posY = 0.04
    local _string = "STRING"
    local _scale = 0.45
    local scale2 = 0.42
    local _font = 4
    if not IsHudHidden() then
        SetTextScale(_scale, _scale)
        SetTextFont(_font)
        SetTextOutline()
        SetTextJustification(1)
        -- SetTextCentre(true)
        -- if t > 1000 then
        --     a = 255 - (t-100)*(500/255)
        -- end
        SetTextColour(r, g, b, a)
        BeginTextCommandDisplayText(_string)
        -- SetScriptVariableHudColour(240,0,0,a)
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(x, y)
    end
end

local raycastTargets = {
	{ -0.5, 10.0, -0.5 },
	{ -0.5, 10.0, 0.0 },
    { -0.5, 10.0, 0.5 },
	
	{ 0.0, 10.0, -0.5 },
	{ 0.0, 10.0, 0.0 },
    { 0.0, 10.0, 0.5 },
	
	{ 0.5, 10.0, -0.5 },
	{ 0.5, 10.0, 0.0 },
	{ 0.5, 10.0, 0.5 },
	
	{ 2.0, 1.0, 0.0},
	{ 2.0, 0.0, 0.0},
	{ 2.0, -1.0, 0.0},
    { -2.0, 1.0, 0.0 },
    { -2.0, 0.0, 0.0 },
    { -2.0, -1.0, 0.0 },
}
function DistSq(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    return (dx*dx)+(dy*dy)+(dz*dz)
end

local function getNearestVeh()
    local pos = GetEntityCoords(GetPlayerPed(-1)) ---@type vector3
    local hit = false
    local vic = 0 ---@type Entity
	local dist = 100.0
	for _,tgt in pairs(raycastTargets) do
		local entityWorld = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), tgt[1], tgt[2], tgt[3])
		local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, GetPlayerPed(-1), 0)
        local _, _, _, _, vehicleHandle = GetRaycastResult(rayHandle)
		if vehicleHandle ~= 0 then
            -- return vehicleHandle
            local vicPos = GetEntityCoords(vehicleHandle)
            local d = DistSq(pos, vicPos)
			-- print(i..": "..vehicleHandle..", "..d.."m^2")
			if d < dist then
				vic = vehicleHandle
				dist = d
			end
		end
	end
	return vic
end

function CanControl(ped)
    if IsPedSittingInAnyVehicle(ped) then return GetVehiclePedIsIn(ped, false) end
	-- local pos = GetEntityCoords(GetPlayerPed(-1),true)
    local veh = getNearestVeh()
    if IsEntityAVehicle(veh) then return veh end
	return 0
end

local c = {
    color = { r = 230, g = 230, b = 230, a = 255 }, -- Text color
    font = 0, -- Text font
    scale = 0.5, -- Text scale
}

function Draw3dText(coords, text)
    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)

    -- Experimental math to scale the text down
    local scale = 200 / (GetGameplayCamFov() * dist)

    -- Format the text
    SetTextColour(c.color.r, c.color.g, c.color.b, c.color.a)
    SetTextScale(0.0, c.scale * scale)
    SetTextFont(c.font)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)

    -- Diplay the text
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function DrawBoxAt(location, size, r, g, b, a)
    local off = vector3(size/2,size/2,size/2)
    DrawBox(location-off, location+off, r, g, b, a)
end