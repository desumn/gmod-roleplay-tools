
RPTools = RPTools or {}

RPTools.Logs = RPTools.Logs or {}

local Format = {}

local bufsize = CreateConVar("rptools_logs_buf_size", 500, nil, "Size of the Roleplay Tools logs buffer")

local buffer = {}
local buffer_index = 1


local function addToBuffer(newLog)
    buffer[buffer_index] = newLog
    buffer_index = (buffer_index + 1) > bufsize:GetInt() and 1 or buffer_index + 1
end

RPTools.Logs.level = {
    debug = 1,
    info = 2,
    warning = 3,
    error = 4
}

local loglevel = CreateConVar("rptools_logs_level", RPTools.Logs.level.warning, nil, "Log level for the Roleplay Tools addon", 0, 3)

function RPTools.Logs.log(level, source, message)
    if level < loglevel:GetInt() then return end

    local curtime = CurTime()
    local date = os.date("*t")

    local newLog = {
        level = level or RPTools.Logs.level.warning,
        curtime = curtime,
        date = date,
        source = tostring(source),
        message = tostring(message)
    }

    addToBuffer(newLog)
end


local warning_format = {
    [RPTools.Logs.level.debug] = "Debug",
    [RPTools.Logs.level.info] = "Info",
    [RPTools.Logs.level.warning] = "Warning",
    [RPTools.Logs.level.error] = "Error"
}

function Format.level(level)
    return warning_format[level] or ""
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

function RPTools.Logs.formatLog(log)

    return "[RPTools | " .. Format.level(log.level) .. " | " .. Format.date(log.date) .. " | " .. Format.time(log.curtime) .. "] "
            .. Format.source(log.source) .. ": " .. Format.message(log.message)

end

concommand.Add("rptools_logs", function (ply, _, args, _)
    local depth = tonumber(args[1]) or 50
    local source = args[2] or ""

    local filtered_log = {}

    for _, log in ipairs(buffer) do
        if !log then continue end
        if source == "" or log.source == source then
            table.insert(filtered_log, log)
        end
    end

    table.sort(filtered_log, function (log1, log2)
        return log1.curtime > log2.curtime
    end)

    for i = 1, math.min(depth, #filtered_log) do
        print(RPTools.Logs.formatLog(filtered_log[i]))
    end

end)