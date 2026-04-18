local selectedIndex = 1
local lastFirstCandidate = nil
local lastCandidatesCount = 0

surface.CreateFont("RPToolsInspectorFont", {
    font = "Roboto",
    extended = true,
    size = 20,
    weight = 600,
    antialias = true,
})

surface.CreateFont("RPToolsInspectorTitleFont", {
    font = "Roboto",
    extended = true,
    size = 24,
    weight = 700,
    antialias = true,
})

local SCOPE = {
    PLAYER = 1,
    GLOBAL = 2,
}

local scopeNames = {
    [SCOPE.PLAYER] = "player",
    [SCOPE.GLOBAL] = "global",
}

local targetNames = {
    player = "→",
    world = "⌖",
    broadcast = "📢",
    state = "✎",
}

-- Constantes visuelles
local PANEL_WIDTH = 280
local PANEL_HEIGHT = 400
local MARGIN_X = 20
local PADDING = 12
local BAND_WIDTH = 4
local LINE_HEIGHT = 22
local INDENT = 10

local COLOR_BG = Color(12, 12, 16, 230)
local COLOR_BAND = Color(0, 230, 255, 200)
local COLOR_TEXT = Color(240, 235, 230)
local COLOR_LABEL = Color(120, 120, 120)
local COLOR_MUTED = Color(100, 100, 100)
local COLOR_ACTIVE = Color(0, 230, 255)
local COLOR_PAUSED = Color(255, 180, 50)
local COLOR_ERROR = Color(255, 80, 80)
local COLOR_INACTIVE = Color(180, 180, 180)

-- Formatters

---@param comparison RPToolsComparison
local function formatComparison(comparison)
    if comparison.equals ~= nil then
        return "= " .. tostring(comparison.equals)
    end
    if comparison.notEquals ~= nil then
        return "≠ " .. tostring(comparison.notEquals)
    end
    
    local parts = {}
    local exclusive = comparison.exclusive or {}
    
    if comparison.min ~= nil then
        local op = exclusive.min and ">" or "≥"
        table.insert(parts, op .. " " .. tostring(comparison.min))
    end
    if comparison.max ~= nil then
        local op = exclusive.max and "<" or "≤"
        table.insert(parts, op .. " " .. tostring(comparison.max))
    end
    
    return table.concat(parts, " and ")
end

---@param condition RPToolsCondition
local function formatCondition(condition)
    if condition.type == "spatial" then
        if condition.test == "distance" then
            return "Distance " .. formatComparison(condition) .. "u"
        elseif condition.test == "view_angle" then
            return "View angle " .. formatComparison(condition)
        elseif condition.test == "line_of_sight" then
            return "Line of sight " .. formatComparison(condition)
        end
    elseif condition.type == "state" then
        local scope = scopeNames[condition.scope] or "?"
        return scope .. "." .. condition.key .. " " .. formatComparison(condition)
    end
    return "?"
end

---@param action RPToolsAction
local function formatAction(action)
    local prefix = targetNames[action.target] or "?"
    
    if action.target == "player" or action.target == "broadcast" then
        if action.action == "send_message" then
            return prefix .. " Message: \"" .. (action.message or "") .. "\""
        elseif action.action == "hud_message" then
            return prefix .. " HUD: \"" .. (action.message or "") .. "\" (" .. (action.duration or 0) .. "s)"
        elseif action.action == "play_sound" then
            return prefix .. " Sound: " .. (action.sound or "?")
        end
    elseif action.target == "world" then
        if action.action == "play_sound" then
            return prefix .. " Spatial sound: " .. (action.sound or "?")
        elseif action.action == "loop_sound" then
            local iter = action.iterations and action.iterations > 0 and (" x" .. action.iterations) or " ∞"
            return prefix .. " Loop: " .. (action.sound or "?") .. iter
        end
    elseif action.target == "state" then
        local scope = scopeNames[action.scope] or "?"
        if action.action == "set" then
            return prefix .. " " .. scope .. "." .. action.key .. " = " .. tostring(action.value)
        elseif action.action == "remove" then
            return prefix .. " remove " .. scope .. "." .. action.key
        end
    end
    
    return prefix .. " ?"
end

-- Utilitaires

local function truncate(text, maxWidth, font)
    surface.SetFont(font)
    
    if surface.GetTextSize(text) <= maxWidth then
        return text
    end
    
    local ellipsis = "..."
    local lo, hi = 1, #text
    while lo < hi do
        local mid = math.ceil((lo + hi) / 2)
        local candidate = string.sub(text, 1, mid) .. ellipsis
        if surface.GetTextSize(candidate) <= maxWidth then
            lo = mid
        else
            hi = mid - 1
        end
    end
    
    return string.sub(text, 1, lo) .. ellipsis
end

---@param trace TraceResult
---@return RPToolsDebugNodeInfos[]
local function findCandidates(trace)
    local candidates = ents.FindInSphere(trace.HitPos, 10)
    local result = {}
    
    for _, candidate in ipairs(candidates) do
        if not IsValid(candidate) or candidate:GetClass() ~= "ent_rptools_node" then
            continue
        end
        if trace.HitPos:Distance(candidate:GetPos()) > 10 then
            continue
        end
        local infos = RPTools.Node.Client.GetNode(candidate:EntIndex())
        if infos then
            table.insert(result, infos)
        end
    end
    
    return result
end

---@param node RPToolsDebugNodeInfos
---@return string, Color
local function getStateDisplay(node)
    if node.state.errorMessage and node.state.errorMessage ~= "" then
        return "Error: " .. node.state.errorMessage, COLOR_ERROR
    elseif node.state.paused then
        return "Paused", COLOR_PAUSED
    elseif node.activePlayers > 0 then
        return "Active (" .. node.activePlayers .. " player(s))", COLOR_ACTIVE
    end
    return "Inactive", COLOR_INACTIVE
end

-- Dessin

---@param x number
---@param y number
---@param node RPToolsDebugNodeInfos
---@param index number
---@param total number
---@return number newY
local function drawHeader(x, y, node, index, total)
    draw.SimpleText("Inspector", "RPToolsInspectorTitleFont",
    x, y, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + 30
    
    if total > 1 then
        draw.SimpleText("Node " .. index .. "/" .. total, "RPToolsInspectorFont",
        x, y, COLOR_INACTIVE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + LINE_HEIGHT
    end
    
    local stateText, stateColor = getStateDisplay(node)
    draw.SimpleText(stateText, "RPToolsInspectorFont",
    x, y, stateColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + 30
    
    return y
end

---@param x number
---@param y number
---@param label string
---@param items any[]
---@param formatter fun(item:any):string
---@param emptyText string
---@param maxWidth number
---@return number newY
local function drawSection(x, y, label, items, formatter, emptyText, maxWidth)
    draw.SimpleText(label, "RPToolsInspectorFont",
    x, y, COLOR_LABEL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + LINE_HEIGHT
    
    if #items == 0 then
        draw.SimpleText(emptyText, "RPToolsInspectorFont",
        x + INDENT, y, COLOR_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        return y + LINE_HEIGHT
    end
    
    for _, item in ipairs(items) do
        local displayText = truncate(formatter(item), maxWidth, "RPToolsInspectorFont")
        draw.SimpleText(displayText, "RPToolsInspectorFont",
        x + INDENT, y, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + LINE_HEIGHT
    end
    
    return y
end

---@param candidates RPToolsDebugNodeInfos[]
---@param selectedIndex number
local function drawPanel(candidates, selectedIndex)
    local node = candidates[selectedIndex]
    
    local x = ScrW() - PANEL_WIDTH - MARGIN_X
    local y = (ScrH() - PANEL_HEIGHT) / 2
    
    surface.SetDrawColor(COLOR_BG)
    surface.DrawRect(x, y, PANEL_WIDTH, PANEL_HEIGHT)
    
    surface.SetDrawColor(COLOR_BAND)
    surface.DrawRect(x, y, BAND_WIDTH, PANEL_HEIGHT)
    
    local textX = x + BAND_WIDTH + PADDING
    local textY = y + PADDING
    local maxTextWidth = PANEL_WIDTH - BAND_WIDTH - (PADDING * 2) - INDENT
    
    textY = drawHeader(textX, textY, node, selectedIndex, #candidates)
    textY = drawSection(textX, textY, "Conditions", node.conditions, formatCondition, "No condition", maxTextWidth)
    textY = textY + 10
    textY = drawSection(textX, textY, "Actions", node.actions, formatAction, "No action", maxTextWidth)
end

hook.Add("HUDPaint", "rptools_inspector_paint", function()
    if not LocalPlayer():GetNW2Bool("rptools_debug", false) then return end
    
    local trace = LocalPlayer():GetEyeTrace()
    local candidates = findCandidates(trace)
    

    lastCandidatesCount = #candidates
    if lastCandidatesCount == 0 then return end
    
    if lastFirstCandidate ~= candidates[1].entIndex then
        selectedIndex = 1
        lastFirstCandidate = candidates[1].entIndex
    else
        selectedIndex = math.min(selectedIndex, #candidates)
    end
    
    
    drawPanel(candidates, selectedIndex)
end)

hook.Add("PlayerButtonDown", "rptools_inspector_controls", function (ply, button)
    if ply ~= LocalPlayer() then return end
    
    local total = lastCandidatesCount
    if total == 0 then return end
    
    if button == KEY_DOWN then
        selectedIndex = (selectedIndex % total) + 1
    elseif button == KEY_UP then
        selectedIndex = ((selectedIndex - 2) % total) + 1
    end
end)