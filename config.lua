Config = {}

Config.allowedCars = { ---@type { hash: TowTruckData}
    [GetHashKey('16ramrb')] = { originBone = 6, attachable = true, attachBone = 7, altRope = { ['front'] = { bone = 2, offset = vector3(0.0, 3.0, 0.0)} } },
    [GetHashKey('16ramrbc')] = { originBone = 10, attachable = true, attachBone = 11 },
    [GetHashKey('hvywrecker')] = { originBone = 2, originOffset = vector3(0.22, 0.0, 0.0), attachable = false, attachBone = 0},
    [GetHashKey('brushram')] = { originBone = 6, attachable = false, attachBone = 0},
    [GetHashKey('af150')] = { originBone = 30, attachable = false, attachBone = 0},
    [GetHashKey('petewreck')] = { originBone = 2, originOffset = vector3(0.3, 0.0, 0.0), attachable = false, attachBone = 0},
    [GetHashKey('17silv')] = { originBone = 7, originOffset = vector3(0.0, 2.0, -0.5), attachable = false, altRope = { ['rear'] = { bone = 1, offset = vector3(0.0, -0.2, -0.5)} } },
    -- [GetHashKey('')] = { originBone = 0, attachable = false, attachBone = 0},
    [GetHashKey('saspf150')] = { originBone = 11, originOffset = vector3(0.0, 3.0, 0.0), attachable = false},
    [GetHashKey('saspf150s')] = { originBone = 10, originOffset = vector3(0.0, 3.0, 0.0), attachable = false},
    [GetHashKey('saspf150cve')] = { originBone = 11, originOffset = vector3(0.0, 3.0, 0.0), attachable = false},
    [GetHashKey('saspram')] = { originBone = 16, originOffset = vector3(0.0, 2.75, 0.0), attachable = false},
    [GetHashKey('sasprams')] = { originBone = 15, originOffset = vector3(0.0, 2.75, 0.0), attachable = false},
}
Config.commands = {
    base = 'tow',
    remote = 'remote',
    rope = 'rope'
}

--- **Dont mess with anything below this line unless you know what you are doing**

Config.events = {
    remote = {
        activate = 'tow:remote:activate',
        deactivate = 'tow:remote:deactivate',
        data = 'tow:remote:data',
        action = 'tow:remote:action'
    },
    getVehicle = 'tow:getVehicle',
    getVehicleReturn = 'tow:getVehicle:return',
    rope = {
        grab = 'tow:rope:grab',
        clear = 'tow:rope:clear',
        attach = 'tow:rope:attach',
        anchor = 'tow:rope:anchor',
        redirect = 'tow:rope:redirect',
        addRedirect = 'tow:rope:addRedirect'
    },
    force = 'tow:force'
}

Config.rope = {
    E = 200e9,      -- Young's Modulus (200 GPa)
    d = 1/2,        -- Diamater of cable (in inches)
}
Config.rope.A = math.pi * ((Config.rope.d * 0.0254 * 0.5) ^ 2) -- Cross section area
Config.towForce = 80067 * 20
--[[
    F = k * x
    x = dist - length
    k = (E*A) / length
]]