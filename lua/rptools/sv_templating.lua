RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

local templateRegister = {}

local function validateDefaultValue(paramType, value)
    return RPTools.Utilities.MakeError((paramType == "number" and RPTools.Utilities.IsNumber(value))
                                    or (paramType == "boolean" and isbool(value))
                                    or (paramType == "string" and isstring(value)),
                                    "type error, waiting for value of type " .. paramType .. " got " .. tostring(value))
end


local function validateParameterType(paramType)
    return RPTools.Utilities.MakeError(isstring(paramType) and 
                                        (paramType == "boolean" or paramType == "number" or paramType == "string"), 
                                            "parameter type must be boolean, number or string")
end

local function validateParameter(parameter)
    if not parameter or not istable(parameter) then
        return nil, "parameter is not a table"
    end

    local isValid = true
    local errorMessage = ""


    local name = parameter.name
    if not isstring(name) or name == "" then 
        errorMessage = errorMessage .. ", name is not a string or is empty"
        isValid = false
    end

    local description = parameter.description
    if not isstring(description) or description == "" then
        errorMessage = errorMessage .. ", description is not a string or is empty"
        isValid = false
    end

    local paramTypeValid, paramTypeError = validateParameterType(parameter.type)
    
    if not paramTypeValid then
        errorMessage = errorMessage .. ", " .. paramTypeError
        isValid = false    local isValid = isValid and parametersValid
    end

    local defaultValue = parameter.default
    local defaultValid, defaultError = true, ""

    if defaultValue == nil then
        defaultValid, defaultError = true, ""
    elseif paramTypeValid then
        defaultValid, defaultError = validateDefaultValue(parameter.type, defaultValue)
    else
        defaultValid = false
    end


    if not defaultValid then
        errorMessage = errorMessage .. ", " .. defaultError
        isValid = false
    end


    if isValid then
        return true, nil
    else
        return false, errorMessage
    end


end


local function validateParameters(parameters)
    local allValid = true
    local errorMessage = ""
    for _, parameter in ipairs(parameters) do
        local validParameter, parameterErrorMessage = validateParameter(parameter)
        if not validParameter then
            allValid = false
            errorMessage = errorMessage .. ", " .. parameterErrorMessage
        end
    end

    if allValid then
        return true, nil
    else 
        return false, errorMessage
    end
end

function RPTools.Templating.ValidateTemplate(template)
    local errorMessage = ""

    local isValid = true
    local name = template.name
    if not isstring(name) or name == "" then 
        errorMessage = errorMessage .. ", name is not a string or is empty"
        isValid = false
    end

    local description = template.description
    if not isstring(description) or description == "" then
        errorMessage = errorMessage .. ", description is not a string or is empty"
        isValid = false
    end

    local parameters = template.parameters

    local parametersValid, parametersErrorMessage = validateParameters(parameters)

    if not parametersValid then
        errorMessage = errorMessage .. ", " .. parametersErrorMessage
        isValid = false
    end

    if not isfunction(template.transformer) then
        errorMessage = errorMessage .. ", no transformation function provided"
        isValid = false
    end

    if not isValid then 
        return false, errorMessage
    else
        return true, nil
    end
end