
RPTools = RPTools or {}
RPTools.Node = RPTools.Node or {}


local logModuleName = "Node"

local counter = 0

local function generateId()
    counter = counter + 1
    return "node_" .. counter
end

function RPTools.Node.generateId(node)
    node.id = generateId()
    return node.id
end

local function validateId(id)
    return RPTools.Utilities.make_error(isstring(id) and id ~= "", "Invalid id " .. tostring(id))
end

local function validatePosition(vector)
    return RPTools.Utilities.make_error(
           isvector(vector) and
           RPTools.Utilities.isnumber(vector.x) and
           RPTools.Utilities.isnumber(vector.y) and
           RPTools.Utilities.isnumber(vector.z), "Invalid vector: " .. tostring(vector))

end

local function validateRequiredTime(time)
    return RPTools.Utilities.make_error(RPTools.Utilities.isnumber(time), "Invalid required time: " .. tostring(time))
end

RPTools.Node.trigger_policy = {
    manual = 1,
    one_shot = 2,
    cooldown = 3,
    continuous = 4,
}

local function validateTriggerPolicy(trigger_policy)
    return RPTools.Utilities.make_error(
        RPTools.Utilities.isnumber(trigger_policy) and trigger_policy >= 1 and trigger_policy <= 4, 
        "Invalid trigger politic: " .. tostring(trigger_policy))
end

RPTools.Node.scope = {
    single_player = 1,
    global = 2,
}

local function validateScope(scope)
    return RPTools.Utilities.make_error(RPTools.Utilities.isnumber(scope) and scope >= 1 and scope <= 2, "Invalid scope: " .. tostring(scope))
end

local function validatePriority(priority)
    return RPTools.Utilities.make_error(RPTools.Utilities.isnumber(priority), "Invalid priority: " .. tostring(priority))
end

local field_validations = {
        id = validateId, 
        position = validatePosition, 
        conditions = RPTools.Condition.validateConditions,
        required_time = validateRequiredTime, 
        actions = RPTools.Actions.validateActions,
        trigger_policy = validateTriggerPolicy,
        scope = validateScope,
        priority = validatePriority}

function RPTools.Node.validateNode(node)

    local final_result = true
    local accumulated_error = ""

    for field, validate in pairs(field_validations) do
        local result, str_error = validate(node[field])
        final_result = final_result and result
        if not result then 
            accumulated_error = str_error .. ", " .. accumulated_error
        end
    end

    return final_result, accumulated_error

end

function RPTools.Node.create(_position, _conditions, _required_time, _actions, _trigger_policy, _scope, _priority)
    local node = {
        id = generateId(),
        position = _position or Vector(0, 0, 0),
        conditions = _conditions or RPTools.Condition.emptyConditionSet(),
        required_time = _required_time or 0,
        actions = _actions or RPTools.Actions.emptyActionSet(),
        trigger_policy = _trigger_policy or RPTools.Node.trigger_policy.one_shot,
        scope = _scope or RPTools.Node.scope.single_player,
        priority = _priority or 0 }

    local isvalid, error_message = RPTools.Node.validateNode(node)

    if isvalid then
        return node, nil
    else
        return nil, error_message
    end
end

function RPTools.Node.getId(node)
    return node.id
end

function RPTools.Node.getPosition(node)
    return node.position
end

function RPTools.Node.getConditions(node)
    return node.conditions
end

function RPTools.Node.getRequiredTime(node)
    return node.required_time
end

function RPTools.Node.getActions(node)
    return node.actions
end

function RPTools.Node.getScope(node)
    return node.scope
end

function RPTools.Node.getPriority(node)
    return node.priority
end

function RPTools.Node.edit(node, subNode)
    local testNode = table.Copy(node)

    table.Merge(testNode, subNode)

    local isvalid, error_message = RPTools.Node.validateNode(testNode)
    if not isvalid then
        return error_message
    end

    table.Merge(node, subNode)
end