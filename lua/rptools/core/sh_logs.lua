RPTools = RPTools or {}

RPTools.Logs = RPTools.Logs or {}

local Format = {}

local bufSize = CreateConVar("rptools_logs_buf_size", 500, nil, "Size of the Roleplay Tools logs buffer")

local buffer = {}
local bufferIndex = 1

local function addToBuffer(newLog)
  buffer[bufferIndex] = newLog
  bufferIndex = (bufferIndex + 1) > bufSize:GetInt() and 1 or bufferIndex + 1
end

---@enum RPToolsLogLevel
RPTools.Logs.LEVEL = {
  DEBUG = 1,
  INFO = 2,
  WARNING = 3,
  ERROR = 4,
}

local logLevel =
  CreateConVar("rptools_logs_level", RPTools.Logs.LEVEL.DEBUG, nil, "Log level for the Roleplay Tools addon", 0, 3)

---@param level RPToolsLogLevel
---@param source string
---@param message string
function RPTools.Logs.log(level, source, message)
  if level < logLevel:GetInt() then
    return
  end

  local curTime = CurTime()
  local date = os.date("*t")

  local newLog = {
    level = level or RPTools.Logs.LEVEL.WARNING,
    curtime = curTime,
    date = date,
    source = tostring(source),
    message = tostring(message),
  }

  addToBuffer(newLog)
end

local warningFormat = {
  [RPTools.Logs.LEVEL.DEBUG] = "Debug",
  [RPTools.Logs.LEVEL.INFO] = "Info",
  [RPTools.Logs.LEVEL.WARNING] = "Warning",
  [RPTools.Logs.LEVEL.ERROR] = "Error",
}

function Format.level(level)
  return warningFormat[level] or ""
end

function Format.time(time)
  return string.NiceTime(time)
end

function Format.date(date)
  return date.day .. "/" .. date.month .. "/" .. date.year .. " | " .. date.hour .. ":" .. date.min .. ":" .. date.sec
end

function Format.source(source)
  return source
end

function Format.message(message)
  return message
end

---@param log RPToolsLog
---@return string
function RPTools.Logs.FormatLog(log)
  return "[RPTools | "
    .. Format.level(log.level)
    .. " | "
    .. Format.date(log.date)
    .. " | "
    .. Format.time(log.curtime)
    .. "] "
    .. Format.source(log.source)
    .. ": "
    .. Format.message(log.message)
end

concommand.Add("rptools_logs", function(ply, _, args, _)
  local depth = tonumber(args[1]) or 50
  local source = args[2] or ""

  local filteredLog = {}

  for _, log in ipairs(buffer) do
    if not log then
      continue
    end
    if source == "" or log.source == source then
      table.insert(filteredLog, log)
    end
  end

  table.sort(filteredLog, function(log1, log2)
    return log1.curtime > log2.curtime
  end)

  for i = 1, math.min(depth, #filteredLog) do
    print(RPTools.Logs.FormatLog(filteredLog[i]))
  end
end)
