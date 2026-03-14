
RPTools = RPTools or {}
RPTools.Condition = RPTools.Condition or {}

function RPTools.Condition.ValidateAction(condition)

    local accumulatedErrorMessage = ""

    local sourceValid, sourceErrorMessage = RPTools.Source.ValidateSource(condition.source)

    if not sourceValid then
        accumulatedErrorMessage = sourceErrorMessage .. ", " .. accumulatedErrorMessage
    end

    local operatorValid, operatorErrorMessage = RPTools.Operators.ValidateOperator(condition.operator)

    if not operatorValid then
        accumulatedErrorMessage = operatorErrorMessage .. ", " .. accumulatedErrorMessage
        return false, accumulatedErrorMessage -- Can't validate the value without the operator
    end

    local valueValid, valueErrorMessage = RPTools.Operators.ValidateValue(condition.operator, condition.value)

    if not valueValid then
        accumulatedErrorMessage = valueErrorMessage .. ", " .. accumulatedErrorMessage
    end

    if not valueValid or not sourceValid then
        return false, accumulatedErrorMessage
    end

    return true, nil
end

function RPTools.Condition.ValidateConditionSet(conditions)

    local allConditionsValid = true
    local accumulatedErrorMessage = ""

    for _, condition in ipairs(conditions) do
        local conditionValid, conditionErrorMessage = RPTools.Condition.ValidateAction(condition)
        allConditionsValid = conditionValid and allConditionsValid
        if not conditionValid then
            accumulatedErrorMessage = conditionErrorMessage .. ", " .. accumulatedErrorMessage
        end
    end

    if not allConditionsValid then
        return false, accumulatedErrorMessage
    else
        return true, nil
    end
end

function RPTools.Condition.Create(source, operator, value)
    local condition = {
        source = source,
        operator = operator,
        value = value
    }

    local conditionValid, conditionErrorMessage = RPTools.Condition.ValidateAction(condition)

    if not conditionValid then
        return nil, conditionErrorMessage
    else
        return condition, nil
    end
end


function RPTools.Condition.GetSource(condition)
    return condition.source
end

function RPTools.Condition.GetOperator(condition)
    return condition.operator
end

function RPTools.Condition.GetValue(condition)
    return condition.value
end

function RPTools.Condition.EmptyConditionSet()
    return {}
end

function RPTools.Condition.CreateConditionSet(conditions)
    local conditionSetValid, conditionErrorMessage = RPTools.Condition.ValidateConditionSet(conditions)

    if not conditionSetValid then
        return nil, conditionErrorMessage
    else
        return conditions, nil
    end
end