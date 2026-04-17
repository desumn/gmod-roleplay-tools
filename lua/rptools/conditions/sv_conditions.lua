---@class RPToolsComparison<T>
---@field equals? T
---@field notEquals? T
---@field min? T
---@field max? T
---@field exclusive { min? : boolean, max? : boolean }



---@generic T
---@param value T
---@param comparison RPToolsComparison<T>
---@return boolean
local function compare(value, comparison)

    if comparison.equals ~= nil then
        if value == nil then return false end
        return value == comparison.equals
    end


    if comparison.notEquals ~= nil then
        return value ~= comparison.notEquals
    end


    if value == nil then return false end
    local min = comparison.min
    local max = comparison.max

    local exclusive = comparison.exclusive or { min = false, max = false }
    exclusive.min = exclusive.min or false
    exclusive.max = exclusive.max or false

    local minCheck = true

    if min ~= nil then
        if exclusive.min then
            minCheck = min < value
        else
            minCheck = min <= value
        end
    end

    local maxCheck = true
    if max ~= nil then
        if exclusive.max then
            maxCheck = value < max
        else
            maxCheck = value <= max
        end
    end

    return minCheck and maxCheck

end

local Data = {}

---@param ply Player
---@param node RPToolsNodeEntity
---@return number
function Data.getDistance(ply, node)
    return ply:GetPos():Distance(node:GetPos())
end

---@param ply Player
---@param node RPToolsNodeEntity
---@return number
function Data.getViewAngle(ply, node)
    local direction = (node:GetPos() - ply:GetShootPos()):GetNormalized()
    return ply:GetAimVector():Dot(direction)
end

---@param ply Player
---@param node RPToolsNodeEntity
---@return boolean
function Data.getLineOfSight(ply, node)
    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = node:GetPos(),
        filter = ply,
    })
    return not tr.Hit
end


---@class RPToolsSpatialCondition : RPToolsComparison<number|boolean>
---@field type "spatial"
---@field test "distance"|"view_angle"|"line_of_sight"

---@param condition RPToolsSpatialCondition
---@param ply Player
---@param node RPToolsNodeEntity
---@return boolean
local function evaluateSpatial(condition, ply, node)
    local position = node:GetPos()

    local value

    if condition.test == "distance" then
        value = Data.getDistance(ply, node)
    elseif condition.test == "view_angle" then
        value = Data.getViewAngle(ply, node)
    elseif condition.test == "line_of_sight" then
        value = Data.getLineOfSight(ply, node)
    end

    if value == nil then return false end
    return compare(value, condition)
end

---@class RPToolsStateCondition : RPToolsComparison<number|boolean>
---@field type "state"
---@field scope RPToolsStateScope
---@field key string

---@param condition RPToolsStateCondition
---@param ply? Player
---@return boolean
local function evaluateState(condition, ply)
    local value = RPTools.State.Get(condition.scope, condition.key, ply)
    return compare(value, condition)
end

---@alias RPToolsCondition RPToolsSpatialCondition | RPToolsStateCondition

---@param conditions RPToolsCondition[]
---@param ply Player
---@param node RPToolsNodeEntity
---@return boolean
function RPTools.Conditions.Evaluate(conditions, ply, node)

    for _, condition in ipairs(conditions) do
        if condition.type == "spatial" then
            if not evaluateSpatial(condition, ply, node) then
                return false
            end
        elseif condition.type == "state" then
            if not evaluateState(condition, ply) then
                return false
            end
        end
    end

    return true
end