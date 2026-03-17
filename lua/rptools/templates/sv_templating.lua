RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

local logModuleName = "Templating"

local templateRegister = {}

function RPTools.Templating.RegisterTemplate(template)
    local isvalid, error_message = RPTools.Templating.ValidateTemplate(template)
    if not isvalid then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to register an invalid template (" .. error_message .. ")")
        return
    end

    local name = template.name

    templateRegister[name] = template
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Added template :" .. name .. " to the template register.")
end

function RPTools.Templating.UnregisterTemplate(templateName)
    if not templateRegister[templateName] then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to unregister a non-existant template (" .. tostring(templateName) .. ")")
        return
    end

    templateRegister[templateName] = nil
    RPTools.Logs.log(RPTools.Logs.LEVEL.INFO, logModuleName, "Removed template :" .. templateName .. " from the template register.")
end

function RPTools.Templating.GetTemplateByName(templateName)
    if not templateRegister[templateName] then
        RPTools.Logs.log(RPTools.Logs.LEVEL.WARNING, logModuleName, "Tried to get a non-existant template (" .. tostring(templateName) .. ")")
        return
    end

    return templateRegister[templateName]
end

local function validateValue(paramType, value)
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
        isValid = false
    end

    local defaultValue = parameter.default
    local defaultValid, defaultError = true, ""

    if defaultValue == nil then
        defaultValid, defaultError = true, ""
    elseif paramTypeValid then
        defaultValid, defaultError = validateValue(parameter.type, defaultValue)
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

local function applyParameters(template, arguments)

    local unprovidedParameters = ""
    local wronglyTypedArguments = ""

    local finalArguments = {}

    for _, parameter in ipairs(template.parameters) do
        if arguments[parameter.name] == nil then
            if parameter.default == nil then
                unprovidedParameters = unprovidedParameters .. ", " .. parameter.name
            else
                finalArguments[parameter.name] = parameter.default
            end
        else
            local valueValid, valueError = validateValue(parameter.type, arguments[parameter.name])
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

function RPTools.Templating.Execute(template, arguments)
    local validatedArguments, argumentsErrorMessage = applyParameters(template, arguments)
    
    if not validatedArguments then
        return nil, argumentsErrorMessage
    end

    return template.transformer(validatedArguments)

end

function RPTools.Templating.GetName(template)
    return template.name
end

function RPTools.Templating.GetParameters(template)
    return table.Copy(template.parameters)
end

function RPTools.Templating.GetTransformer(template)
    return template.transformer
end

function RPTools.Templating.GetDescription(template)
    return template.description
end