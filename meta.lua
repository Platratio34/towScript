---@meta

---@class TowTruck
---@field holder ServerPlayer Current controlling player
---@field dist number Distance between ends
---@field length number Current rope length
---@field maxLength number Maximum rope length. Default 50
---@field netid NetEntity Source vehicle netid
---@field point string|nil Alternant rope point
---@field other RopePoint End of rope (currently only an vehicle)
---@field redirect RopePoint Redirect point
---@field attached boolean Rope attached to end point
---@field vicData TowTruckData Truck data
---@field remotes table<ServerPlayer, boolean> Table of all players with remotes

---@class RopePoint
---@field active boolean Redirect Only. If the redirect is active
---@field netid NetEntity NetId of entity the point is on, or -1 for static
---@field pos vector3 Current position of entity, or static position
---@field offset vector3 Offset from entity position

---@class TowTruckData
---@field originBone integer Rope origin bone index
---@field originOffset vector3|nil Rope origin offset from bone
---@field attachable boolean If the truck can be attached to
---@field attachBone integer|nil Attachment bone index
---@field altRope table<string, BoneOffset>|nil

---@class BoneOffset
---@field bone integer
---@field offset vector3|nil