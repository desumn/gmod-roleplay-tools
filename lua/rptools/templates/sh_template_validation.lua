RPTools = RPTools or {}
RPTools.Templating = RPTools.Templating or {}

local function validateName(name)
  if isstring(name) and name ~= "" then
    return true
  else
    return false, "Invalid description: " .. name
  end
end

local function validateDescription(description)
  if isstring(description) and description ~= "" then
    return true
  else
    return false, "Invalid description: " .. description
  end
end

local parameterTypes = {
  string = {
    validate = isstring,
  },
  number = {
    validate = RPTools.Utilities.IsNumber,
    min = RPTools.Utilities.IsNumber,
    max = RPTools.Utilities.IsNumber,
  },
  boolean = {
    validate = isbool,
  },
}

local function validateParameters(parameters)
  local errors = ""
  local isValid = true

  for _, parameter in pairs(parameters) do
    local name = parameter.name
    if not isstring(name) or name == "" then
      isValid = false
      errors = tostring(name) .. " name: " .. (tostring(name) or "not provided") .. " is invalid" .. ", " .. errors
      name = tostring(name)
    end

    local desc = parameter.description
    if not isstring(desc) or desc == "" then
      isValid = false
      errors = name .. " description: " .. (tostring(desc) or "not provided") .. " is invalid" .. ", " .. errors
    end

    local required = parameter.required
    if not isbool(required) then
      isValid = false
      errors = name .. " required: " .. (tostring(required) or "not provided") .. " is invalid" .. ", " .. errors
    end

    local group = parameter.group
    if not isstring(group) or group == "" then
      isValid = false
      errors = name .. " group: " .. (tostring(group) or "not provided") .. " is invalid" .. ", " .. errors
    end

    local type = parameter.type
    local typeValid = true
    if not isstring(type) or parameterTypes[type] == nil then
      isValid = false
      typeValid = false
      errors = name .. " type " .. (tostring(type) or "not provided") .. " is invalid " .. ", " .. errors
    end

    if typeValid then
      local default = parameter.default

      if default and not parameterTypes[type].validate(default) then
        isValid = false
        errors = name
          .. " default type (required "
          .. tostring(type)
          .. ")"
          .. ":"
          .. tostring(default)
          .. "is invalid "
          .. ", "
          .. errors
      end

      if table.Count(parameterTypes[type]) > 1 then
        for field, validator in pairs(parameterTypes[type]) do
          if field == "validate" then
            continue
          end
          local paramField = parameter[field]
          if paramField and not validator(paramField) then
            isValid = false
            errors = name
              .. " "
              .. tostring(field)
              .. "  (required type "
              .. tostring(type)
              .. ")"
              .. ":"
              .. tostring(paramField)
              .. "is invalid "
              .. ", "
              .. errors
          end
        end
      end
    end
  end

  if isValid then
    return true
  else
    return false, errors
  end
end

function RPTools.Templating.ValidateTemplate(template)
  local isValid = true
  local errors = ""
  local nameValid, nameError = validateName(template.name)
  if not nameValid then
    isValid = false
    errors = nameError .. ", " .. errors
  end

  local descValid, descError = validateDescription(template.description)
  if not descValid then
    isValid = false
    errors = descError .. ", " .. errors
  end

  local paramsValid, paramsError = validateParameters(template.parameters)
  if not paramsValid then
    isValid = false
    errors = paramsError .. ", " .. errors
  end

  if SERVER then
    if not isfunction(template.transformer) then
      isValid = false
      errors = "transofrmer not valid" .. ", " .. errors
    end
  end

  if not isValid then
    return false, errors
  else
    return true
  end
end

---@param template RPToolsTemplate
---@param args table
function RPTools.Templating.Apply(template, args)
  local finalArgs = {}
  local errors = ""
  for param, infos in pairs(template.parameters) do
    if not args[param] then
      if infos.default == nil and infos.required then
        errors = "parameter " .. param .. " not provided," .. errors
        continue
      end
      if infos.default ~= nil then
        finalArgs[param] = infos.default
      end
    else
      if not parameterTypes[infos.type].validate(args[param]) then
        errors = "parameter "
          .. param
          .. " has wrong type, got "
          .. type(args[param])
          .. " expected "
          .. infos.type
          .. errors
        continue
      end
      finalArgs[param] = args[param]
    end
  end

  if errors ~= "" then
    return nil, errors
  else
    return finalArgs
  end
end
