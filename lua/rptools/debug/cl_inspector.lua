RPTools = RPTools or {}

local selectedIndex = 1
local selectedENTIndex = nil
local lastFirstCandidate = nil
local lastCandidatesCount = 0
local isDetailed = false

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

surface.CreateFont("RPToolsInspectorSmallFont", {
  font = "Roboto",
  extended = true,
  size = 16,
  weight = 500,
  antialias = true,
})

local SCOPE = RPTools.State.Shared.SCOPE

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

local PANEL_WIDTH_NORMAL = 280
local PANEL_WIDTH_DETAILED = 450
local MARGIN_X = 20
local PADDING = 12
local BAND_WIDTH = 4
local LINE_HEIGHT = 22
local DETAIL_LINE_HEIGHT = 20
local INDENT = 10
local DETAIL_INDENT = 20
local HEADER_TITLE_GAP = 30
local HEADER_STATE_GAP = 30
local SECTION_GAP = 10
local ITEM_GAP = 4
local FOOTER_HEIGHT = 30
local FOOTER_MARGIN = 12

local COLOR_BG = Color(12, 12, 16, 230)
local COLOR_BAND = Color(0, 230, 255, 200)
local COLOR_TEXT = Color(240, 235, 230)
local COLOR_DETAIL = Color(180, 180, 190)
local COLOR_LABEL = Color(120, 120, 120)
local COLOR_MUTED = Color(100, 100, 100)
local COLOR_ACTIVE = Color(0, 230, 255)
local COLOR_PAUSED = Color(255, 180, 50)
local COLOR_ERROR = Color(255, 80, 80)
local COLOR_INACTIVE = Color(180, 180, 180)
local COLOR_SHORTCUT_KEY = Color(200, 200, 210)
local COLOR_SHORTCUT_DESC = Color(130, 130, 140)

---@param range RPToolsRange
---@return string
local function formatRange(range)
  local parts = {}
  local exclusive = range.exclusive or {}

  if range.min ~= nil then
    local op = exclusive.min and ">" or "≥"
    table.insert(parts, op .. " " .. tostring(range.min))
  end
  if range.max ~= nil then
    local op = exclusive.max and "<" or "≤"
    table.insert(parts, op .. " " .. tostring(range.max))
  end

  return table.concat(parts, " and ")
end

---@generic T
---@param equality RPToolsEquality<T>
---@return string
local function formatEquality(equality)
  if equality.equals ~= nil then
    return "= " .. tostring(equality.equals)
  end
  if equality.notEquals ~= nil then
    return "≠ " .. tostring(equality.notEquals)
  end
  return "?"
end

---@param condition RPToolsCondition
---@return string
local function formatCondition(condition)
  if condition.type == "spatial" then
    if condition.test == "distance" then
      return "Distance " .. formatRange(condition) .. "u"
    elseif condition.test == "view_angle" then
      local angleDeg = math.floor(math.deg(math.acos(condition.min)))
      return "View angle ≤ " .. angleDeg .. "°"
    elseif condition.test == "line_of_sight" then
      return "Line of sight " .. formatEquality(condition)
    else
      error("format failed: invalid condition test" .. condition.test)
    end
  elseif condition.type == "state" then
    local scope = scopeNames[condition.scope] or "?"
    local key = scope .. "." .. condition.key
    if condition.valueType == "boolean" or condition.valueType == "string" then
      return key .. " " .. formatEquality(condition)
    elseif condition.valueType == "number" then
      return key .. " " .. formatRange(condition)
    else
      error("format failed: invalid condition test" .. condition.test)
    end
  else
    error("unhandled condition type " .. condition.type)
  end
end

---@param action RPToolsAction
---@return string
local function formatAction(action)
  local prefix = targetNames[action.target] or "?"

  if action.target == "player" then
    if action.action == "send_message" then
      return prefix .. " Message"
    elseif action.action == "hud_message" then
      return prefix .. " HUD message (" .. action.duration .. "s)"
    elseif action.action == "play_sound" then
      return prefix .. " Sound"
    else
      error("format failed: invalid action type" .. action.action)
    end
  elseif action.target == "world" then
    if action.action == "play_sound" then
      return prefix .. " Spatial sound"
    elseif action.action == "loop_sound" then
      local iter = action.iterations and action.iterations > 0 and (" x" .. action.iterations) or " ∞"
      return prefix .. " Loop" .. iter
    else
      error("format failed: invalid action type" .. action.action)
    end
  elseif action.target == "broadcast" then
    return prefix .. " Message"
  elseif action.target == "state" then
    local scope = scopeNames[action.scope] or "?"
    if action.action == "set" then
      return prefix .. " " .. scope .. "." .. action.key .. " = " .. tostring(action.value) .. " (" .. action.valueType .. ")"
    elseif action.action == "remove" then
      return prefix .. " remove " .. scope .. "." .. action.key
    else
      error("format failed: invalid action type" .. action.action)
    end
  else
    error("format error: unknwon action target " .. action.target)
  end
end

---@param action RPToolsAction
---@return string[]
local function actionDetails(action)
  local details = {}

  if action.target == "player" or action.target == "broadcast" then
    if action.action == "send_message" or action.action == "hud_message" then
      table.insert(details, '"' .. action.message .. '"')
    elseif action.action == "play_sound" then
      table.insert(details, action.sound)
      if action.volume then
        table.insert(details, "vol " .. action.volume)
      end
      if action.pitch then
        table.insert(details, "pitch " .. action.pitch)
      end
    end
  elseif action.target == "world" then
    table.insert(details, action.sound)
    if action.volume then
      table.insert(details, "vol " .. action.volume)
    end
    if action.pitch then
      table.insert(details, "pitch " .. action.pitch)
    end
    if action.level then
      table.insert(details, "level " .. action.level)
    end
  end

  return details
end

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

local function wrapText(text, maxWidth, font)
  surface.SetFont(font)
  local words = string.Explode(" ", text)
  local lines = {}
  local currentLine = ""

  for _, word in ipairs(words) do
    local testLine = currentLine == "" and word or (currentLine .. " " .. word)
    if surface.GetTextSize(testLine) > maxWidth and currentLine ~= "" then
      table.insert(lines, currentLine)
      currentLine = word
    else
      currentLine = testLine
    end
  end

  if currentLine ~= "" then
    table.insert(lines, currentLine)
  end

  return lines
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

-- Mesure

---@param total number
---@return number
local function measureHeader(total)
  local h = HEADER_TITLE_GAP
  if total > 1 then
    h = h + LINE_HEIGHT
  end
  h = h + HEADER_STATE_GAP
  return h
end

---@param items any[]
---@return number
local function measureCompactItems(items)
  if #items == 0 then
    return LINE_HEIGHT
  end
  return #items * LINE_HEIGHT
end

---@param actions RPToolsAction[]
---@param maxWidth number
---@return number
local function measureDetailedActions(actions, maxWidth)
  if #actions == 0 then
    return LINE_HEIGHT
  end

  local h = 0
  for i, action in ipairs(actions) do
    if i > 1 then
      h = h + ITEM_GAP
    end
    h = h + LINE_HEIGHT

    local details = actionDetails(action)
    local detailMaxWidth = maxWidth - DETAIL_INDENT
    for _, detail in ipairs(details) do
      local wrapped = wrapText(detail, detailMaxWidth, "RPToolsInspectorFont")
      h = h + #wrapped * DETAIL_LINE_HEIGHT
    end
  end

  return h
end

---@param node RPToolsDebugNodeInfos
---@param total number
---@param maxWidth number
---@return number
local function measurePanelContent(node, total, maxWidth)
  local h = PADDING
  h = h + measureHeader(total)
  h = h + LINE_HEIGHT -- label Conditions
  h = h + measureCompactItems(node.conditions)
  h = h + SECTION_GAP
  h = h + LINE_HEIGHT -- label Actions
  if isDetailed then
    h = h + measureDetailedActions(node.actions, maxWidth)
  else
    h = h + measureCompactItems(node.actions)
  end
  h = h + FOOTER_MARGIN
  h = h + FOOTER_HEIGHT
  return h
end

-- Dessin

---@param x number
---@param y number
---@param node RPToolsDebugNodeInfos
---@param index number
---@param total number
---@return number newY
local function drawHeader(x, y, node, index, total)
  draw.SimpleText("Inspector", "RPToolsInspectorTitleFont", x, y, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  y = y + HEADER_TITLE_GAP

  if total > 1 then
    draw.SimpleText(
      "Node " .. index .. "/" .. total,
      "RPToolsInspectorFont",
      x,
      y,
      COLOR_INACTIVE,
      TEXT_ALIGN_LEFT,
      TEXT_ALIGN_TOP
    )
    y = y + LINE_HEIGHT
  end

  local stateText, stateColor = getStateDisplay(node)
  draw.SimpleText(stateText, "RPToolsInspectorFont", x, y, stateColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  y = y + HEADER_STATE_GAP

  return y
end

---@param x number
---@param y number
---@param label string
---@return number newY
local function drawLabel(x, y, label)
  draw.SimpleText(label, "RPToolsInspectorFont", x, y, COLOR_LABEL, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  return y + LINE_HEIGHT
end

---@param x number
---@param y number
---@param items any[]
---@param formatter fun(item:any):string
---@param emptyText string
---@param maxWidth number
---@return number newY
local function drawCompactItems(x, y, items, formatter, emptyText, maxWidth)
  if #items == 0 then
    draw.SimpleText(emptyText, "RPToolsInspectorFont", x + INDENT, y, COLOR_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    return y + LINE_HEIGHT
  end

  for _, item in ipairs(items) do
    local displayText = truncate(formatter(item), maxWidth, "RPToolsInspectorFont")
    draw.SimpleText(displayText, "RPToolsInspectorFont", x + INDENT, y, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + LINE_HEIGHT
  end

  return y
end

---@param x number
---@param y number
---@param actions RPToolsAction[]
---@param maxWidth number
---@return number newY
local function drawDetailedActions(x, y, actions, maxWidth)
  if #actions == 0 then
    draw.SimpleText("No action", "RPToolsInspectorFont", x + INDENT, y, COLOR_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    return y + LINE_HEIGHT
  end

  for i, action in ipairs(actions) do
    if i > 1 then
      y = y + ITEM_GAP
    end

    local shortText = truncate(formatAction(action), maxWidth, "RPToolsInspectorFont")
    draw.SimpleText(shortText, "RPToolsInspectorFont", x + INDENT, y, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    y = y + LINE_HEIGHT

    local details = actionDetails(action)
    local detailMaxWidth = maxWidth - DETAIL_INDENT
    for _, detail in ipairs(details) do
      local wrapped = wrapText(detail, detailMaxWidth, "RPToolsInspectorFont")
      for _, line in ipairs(wrapped) do
        draw.SimpleText(
          line,
          "RPToolsInspectorFont",
          x + DETAIL_INDENT,
          y,
          COLOR_DETAIL,
          TEXT_ALIGN_LEFT,
          TEXT_ALIGN_TOP
        )
        y = y + DETAIL_LINE_HEIGHT
      end
    end
  end

  return y
end

---@param x number
---@param y number
---@param panelWidth number
---@param hasMultiple boolean
local function drawFooter(x, y, panelWidth, hasMultiple)
  local textX = x + BAND_WIDTH + PADDING

  surface.SetFont("RPToolsInspectorSmallFont")

  local shortcuts = {}
  if hasMultiple then
    table.insert(shortcuts, { key = "↑/↓", desc = "navigate" })
  end
  table.insert(shortcuts, { key = "Caps", desc = isDetailed and "compact" or "details" })

  local currentX = textX
  for i, s in ipairs(shortcuts) do
    if i > 1 then
      currentX = currentX + 8
    end

    draw.SimpleText(
      s.key,
      "RPToolsInspectorSmallFont",
      currentX,
      y,
      COLOR_SHORTCUT_KEY,
      TEXT_ALIGN_LEFT,
      TEXT_ALIGN_TOP
    )
    local keyWidth = surface.GetTextSize(s.key)
    currentX = currentX + keyWidth + 4

    draw.SimpleText(
      s.desc,
      "RPToolsInspectorSmallFont",
      currentX,
      y,
      COLOR_SHORTCUT_DESC,
      TEXT_ALIGN_LEFT,
      TEXT_ALIGN_TOP
    )
    local descWidth = surface.GetTextSize(s.desc)
    currentX = currentX + descWidth
  end
end

---@param candidates RPToolsDebugNodeInfos[]
---@param selectedIndex number
local function drawPanel(candidates, selectedIndex)
  local node = candidates[selectedIndex]

  local panelWidth = isDetailed and PANEL_WIDTH_DETAILED or PANEL_WIDTH_NORMAL
  local maxTextWidth = panelWidth - BAND_WIDTH - (PADDING * 2) - INDENT
  local panelHeight = measurePanelContent(node, #candidates, maxTextWidth)

  local x = ScrW() - panelWidth - MARGIN_X
  local y = (ScrH() - panelHeight) / 2

  surface.SetDrawColor(COLOR_BG)
  surface.DrawRect(x, y, panelWidth, panelHeight)

  surface.SetDrawColor(COLOR_BAND)
  surface.DrawRect(x, y, BAND_WIDTH, panelHeight)

  local textX = x + BAND_WIDTH + PADDING
  local textY = y + PADDING

  textY = drawHeader(textX, textY, node, selectedIndex, #candidates)

  textY = drawLabel(textX, textY, "Conditions")
  textY = drawCompactItems(textX, textY, node.conditions, formatCondition, "No condition", maxTextWidth)

  textY = textY + SECTION_GAP

  textY = drawLabel(textX, textY, "Actions")
  if isDetailed then
    textY = drawDetailedActions(textX, textY, node.actions, maxTextWidth)
  else
    textY = drawCompactItems(textX, textY, node.actions, formatAction, "No action", maxTextWidth)
  end

  drawFooter(x, y + panelHeight - FOOTER_HEIGHT, panelWidth, #candidates > 1)
end

hook.Add("HUDPaint", "rptools_inspector_paint", function()
  if not LocalPlayer():GetNW2Bool("rptools_debug", false) then
    return
  end

  local trace = LocalPlayer():GetEyeTrace()
  local candidates = findCandidates(trace)
  lastCandidatesCount = #candidates

  if not table.IsEmpty(candidates) and lastFirstCandidate ~= candidates[1].entIndex then
    selectedIndex = 1
    lastFirstCandidate = candidates[1].entIndex
  elseif not table.IsEmpty(candidates) then
    selectedIndex = math.min(selectedIndex, #candidates)
  end

  if not table.IsEmpty(candidates) then
    selectedENTIndex = candidates[selectedIndex].entIndex
    drawPanel(candidates, selectedIndex)
  else
    if selectedENTIndex ~= nil and IsValid(Entity(selectedENTIndex)) then
      drawPanel({ RPTools.Node.Client.GetNode(selectedENTIndex) }, 1)
    end
  end
end)

hook.Add("PlayerButtonDown", "rptools_inspector_controls", function(ply, button)
  if ply ~= LocalPlayer() then
    return
  end

  if button == KEY_CAPSLOCK then
    isDetailed = not isDetailed
    return
  end

  local total = lastCandidatesCount
  if total == 0 then
    return
  end

  if button == KEY_DOWN then
    selectedIndex = (selectedIndex % total) + 1
  elseif button == KEY_UP then
    selectedIndex = ((selectedIndex - 2) % total) + 1
  end
end)

---@param node Entity
---@return boolean
local function isSelected(node)
  return node:EntIndex() == selectedENTIndex
end

---@return number|nil
local function getSelectedEntIndex()
  return selectedENTIndex
end

local function clearSelection()
  selectedENTIndex = nil
end

RPTools.Inspector = {
  IsSelected = isSelected,
  GetSelectedEntIndex = getSelectedEntIndex,
  ClearSelection = clearSelection,
}
