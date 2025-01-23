function MulNumber(vector1, value)
    local result = {}
    result.x = vector1.x * value
    result.y = vector1.y * value
    result.z = vector1.z * value
    return result
end

-- Add one vector to another.
function AddVector3(vector1, vector2) 
    return {x = vector1.x + vector2.x, y = vector1.y + vector2.y, z = vector1.z + vector2.z}   
end

-- Subtract one vector from another.
function SubVector3(vector1, vector2) 
    return {x = vector1.x - vector2.x, y = vector1.y - vector2.y, z = vector1.z - vector2.z}
end

function RotationToDirection(rotation) 
    local z = DegToRad(rotation.z)
    local x = DegToRad(rotation.x)
    local num = math.abs(math.cos(x))

    local result = {}
    result.x = -math.sin(z) * num
    result.y = math.cos(z) * num
    result.z = math.sin(x)
    return result
end

function W2s(position)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(position.x, position.y, position.z)
    if not onScreen then
        return nil
    end

    local newPos = {}
    newPos.x = (_x - 0.5) * 2
    newPos.y = (_y - 0.5) * 2
    newPos.z = 0
    return newPos
end

function ProcessCoordinates(x, y) 
    local screenX, screenY = GetActiveScreenResolution()

    local relativeX = 1 - (x / screenX) * 1.0 * 2
    local relativeY = 1 - (y / screenY) * 1.0 * 2

    if relativeX > 0.0 then
        relativeX = -relativeX;
    else
        relativeX = math.abs(relativeX)
    end

    if relativeY > 0.0 then
        relativeY = -relativeY
    else
        relativeY = math.abs(relativeY)
    end

    return { x = relativeX, y = relativeY }
end

function S2w(camPos, relX, relY)
    local camRot = GetGameplayCamRot(0)
    local camForward = RotationToDirection(camRot)
    local rotUp = AddVector3(camRot, { x = 10, y = 0, z = 0 })
    local rotDown = AddVector3(camRot, { x = -10, y = 0, z = 0 })
    local rotLeft = AddVector3(camRot, { x = 0, y = 0, z = -10 })
    local rotRight = AddVector3(camRot, { x = 0, y = 0, z = 10 })

    local camRight = SubVector3(RotationToDirection(rotRight), RotationToDirection(rotLeft))
    local camUp = SubVector3(RotationToDirection(rotUp), RotationToDirection(rotDown))

    local rollRad = -DegToRad(camRot.y)
    -- print(rollRad)
    local camRightRoll = SubVector3(MulNumber(camRight, math.cos(rollRad)), MulNumber(camUp, math.sin(rollRad)))
    local camUpRoll = AddVector3(MulNumber(camRight, math.sin(rollRad)), MulNumber(camUp, math.cos(rollRad)))

    local point3D = AddVector3(AddVector3(AddVector3(camPos, MulNumber(camForward, 10.0)), camRightRoll), camUpRoll)

    local point2D = W2s(point3D)

    if point2D == nil then
        return AddVector3(camPos, MulNumber(camForward, 10.0))
    end

    local point3DZero = AddVector3(camPos, MulNumber(camForward, 10.0))
    local point2DZero = W2s(point3DZero)

    if point2DZero == nil then
        return AddVector3(camPos, MulNumber(camForward, 10.0))
    end

    local eps = 0.001

    if math.abs(point2D.x - point2DZero.x) < eps or math.abs(point2D.y - point2DZero.y) < eps then
        return AddVector3(camPos, MulNumber(camForward, 10.0))
    end

    local scaleX = (relX - point2DZero.x) / (point2D.x - point2DZero.x)
    local scaleY = (relY - point2DZero.y) / (point2D.y - point2DZero.y)
    local point3Dret = AddVector3(AddVector3(AddVector3(camPos, MulNumber(camForward, 10.0)), MulNumber(camRightRoll, scaleX)), MulNumber(camUpRoll, scaleY))

    return point3Dret
end

function DegToRad(deg)
    return (deg * math.pi) / 180.0
end

-- Get entity, ground, etc. targeted by mouse position in 3D space.
---comment
---@param flags integer 
---@param ignore integer Entity to ignore or 0
---@param center nil|boolean OPTIONAL if the center of the screen should be used
---@return boolean hit
---@return vector3 hitCoords
---@return Entity entityHit
---@return vector3 endCoords
function ScreenToWorld(flags, ignore, center)
    local x, y = GetNuiCursorPosition()

    local absoluteX = x
    local absoluteY = y
    local processedCoords = ProcessCoordinates(absoluteX, absoluteY)
    if center then
        processedCoords = { x=0, y=0 }
    end

    local camPos = GetGameplayCamCoord()
    local target = S2w(camPos, processedCoords.x, processedCoords.y)

    local dir = SubVector3(target, camPos)
    local from = AddVector3(camPos, MulNumber(dir, 0.05))
    local to = AddVector3(camPos, MulNumber(dir, 300))

    local ray = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignore, 0)
    local a, b, c, d, e = GetShapeTestResult(ray)
    -- while a < 2 do
    --     a, b, c, d, e = GetShapeTestResult(ray)
    --     Citizen.Wait()
    -- end
    -- print(a)
    return b, c, e, to
end
