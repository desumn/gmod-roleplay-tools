RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

local displayType = {
    ["string"] = {
        ["short"] = true,
        ["long"] = true
    }
}

local function validateDisplay(paramType, display)
    return RPTools.Utilities.MakeError(displayType[paramType][display] == true, "display type invalid " .. tostring(display) .. " for " .. tostring(paramType))
end

function RPTools.Templating.ValidateValue(paramType, value)
    return RPTools.Utilities.MakeError((paramType == "number" and RPTools.Utilities.IsNumber(value))
    or (paramType == "boolean" and isbool(value))
    or (paramType == "string" and isstring(value)),
    "type error, expecting for value of type " .. paramType .. " got " .. tostring(value))
end

local function validateParameterType(paramType)
    return RPTools.Utilities.MakeError(isstring(paramType) and 
    (paramType == "boolean" or paramType == "number" or paramType == "string"), 
    "parameter type must be boolean, number or string")
end

function RPTools.Templating.ValidateParameter(parameter)
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
    
    local required = parameter.required
    if not isbool(required) then
        errorMessage = errorMessage .. ", requirement not defined or is not bool"
        isValid = false
    end
    
    local paramTypeValid, paramTypeError = validateParameterType(parameter.type)
    
    if not paramTypeValid then
        errorMessage = errorMessage .. ", " .. paramTypeError
        isValid = false
    end
    
    local defaultValue = parameter.default
    local display = parameter.display
    local defaultValid, defaultError = true, ""
    local displayValid, displayError = true, ""
    
    
    if defaultValue == nil then
        defaultValid, defaultError = true, ""
    elseif paramTypeValid then
        defaultValid, defaultError = RPTools.Templating.ValidateValue(parameter.type, defaultValue)
    else
        defaultValid = false
    end
    
    if display == nil then 
        displayValid, displayError = true, ""
    elseif paramTypeValid then
        displayValid, displayError = validateDisplay(parameter.type, display)
    else
        displayValid = false
    end
    
    
    if not defaultValid then
        errorMessage = errorMessage .. ", " .. defaultError
        isValid = false
    end
    
    if not displayValid then
        errorMessage = errorMessage .. ", " .. displayError
        isValid = false
    end
    
    if isValid then
        return true, nil
    else
        return false, errorMessage
    end
end

function RPTools.Templating.ValidateParameters(parameters)
    local allValid = true
    local errorMessage = ""
    for _, parameter in ipairs(parameters) do
        local validParameter, parameterErrorMessage = RPTools.Templating.ValidateParameter(parameter)
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


function RPTools.Templating.ApplyParameters(template, arguments)
    
    local unprovidedParameters = ""
    local wronglyTypedArguments = ""
    
    local finalArguments = {}
    
    for _, parameter in ipairs(template.parameters) do
        if arguments[parameter.name] == nil then
            if parameter.default == nil and parameter.required then
                unprovidedParameters = unprovidedParameters .. ", " .. parameter.name
            else
                finalArguments[parameter.name] = parameter.default
            end
        else
            local valueValid, valueError = RPTools.Templating.ValidateValue(parameter.type, arguments[parameter.name])
            if valueValid then
                finalArguments[parameter.name] = arguments[parameter.name]
            else
                wronglyTypedArguments = wronglyTypedArguments .. ", " .. valueError
            end
        end
    end
    
    if wronglyTypedArguments == "" and unprovidedParameters == "" then
        return finalArguments, nil
    else
        return nil, "unprovided: " .. unprovidedParameters .. "and wrongly typed: " .. wronglyTypedArguments
    end
end