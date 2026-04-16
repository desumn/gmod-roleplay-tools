TOOL.Category = "RPTools"
TOOL.Name = "Node Spawner"

TOOL.Information = {
  { name = "left" },
  { name = "right" },
  { name = "reload" },
}

if CLIENT then
  language.Add("tool.rptools_spawner.name", "Node Spawner")
  language.Add("tool.rptools_spawner.desc", "Place and manage RPTools nodes")
  language.Add("tool.rptools_spawner.left", "Place a node")
  language.Add("tool.rptools_spawner.right", "Delete selected node")
  language.Add("tool.rptools_spawner.reload", "Cycle node selection")
end

local selectedIndex = 1
local visibleNodeCache = {
  lastCalculation = 0,
  length = 0,
  data = {},
}

if CLIENT then
  local maxDistance = 750
  local maxEyeDistance = 22

  local function detectNodes()
    local nodes = RPTools.Debug.GetDebugNodes()

    local eyePos = EyePos()
    local direction = EyeAngles():Forward()
    local visibleNodes = {}

    for _, node in ipairs(nodes) do
      local nodeEyeVector = RPTools.Debug.ResolvePosition(node) - eyePos
      if nodeEyeVector:Dot(direction) <= 0 then
        continue
      end
      if nodeEyeVector:LengthSqr() >= maxDistance * maxDistance then
        continue
      end
      local perpendicularDistance = nodeEyeVector:Cross(direction):Length()
      if perpendicularDistance > maxEyeDistance then
        continue
      end

      table.insert(visibleNodes, { node = node, perpendicularDistance = perpendicularDistance })
    end

    table.sort(visibleNodes, function(a, b)
      return a.perpendicularDistance < b.perpendicularDistance
    end)

    visibleNodeCache.lastCalculation = CurTime()
    visibleNodeCache.data = visibleNodes

    if visibleNodeCache.length ~= #visibleNodes then
      selectedIndex = 1
    end
    visibleNodeCache.length = #visibleNodes
  end

  RPTools.UI.CurrentTemplate = ""
  RPTools.UI.CurrentParams = {}

  function TOOL.BuildCPanel(panel)
    panel:Help("1. Select a template.\n2. Configure the template.\n3. Spawn a node from this template.")

    local templateList = RPTools.UI.BuildTemplateList(panel)

    local sep = vgui.Create("DPanel")
    sep:SetTall(2)

    sep.Paint = function(self, w, h)
      surface.SetDrawColor(0, 0, 0, 100)

      surface.DrawRect(0, 0, w, h)
    end

    panel:AddItem(sep)

    local formWidgets = {}

    local stateIndicator = vgui.Create("DLabel", panel)
    stateIndicator.Paint = function(self, w, h)
      draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 150))

      surface.SetDrawColor(255, 255, 255, 20)
      surface.DrawOutlinedRect(0, 0, w, h)
    end
    stateIndicator:SetTall(50)
    stateIndicator:SetText("Select a template...")
    stateIndicator:SetContentAlignment(5)
    stateIndicator:SetWrap(true)
    stateIndicator:SetAutoStretchVertical(true)
    stateIndicator:SetFont("DermaDefaultBold")
    stateIndicator:SetTextColor(Color(30, 30, 30))
    stateIndicator:DockMargin(5, 10, 5, 5)
    stateIndicator:SetTextInset(10, 0)
    stateIndicator:SetFont("Trebuchet18")

    panel:AddItem(stateIndicator)

    local template = {}
    local arguments = {}

    templateList.OnRowSelected = function(_, rowIndex, row)
      template = RPTools.Templating.GetTemplateByName(row.name)
      RPTools.UI.BuildTemplateForm(panel, template, formWidgets)
      stateIndicator:SetText("Template not valid - please fill the required parameters.")
      arguments = {}
      for name, parameter in pairs(template.parameters) do
        if parameter.default ~= nil then
          arguments[name] = parameter.default
        end
      end
    end

    hook.Add("RPTools_Template_Value_Change", templateList, function(_, name, newValue)
      arguments[name] = (RPTools.Utilities.NonEmpty(newValue) and newValue) or nil
      local newFinalArguments = RPTools.Templating.Apply(template, arguments)

      if newFinalArguments then
        RPTools.UI.CurrentParams = newFinalArguments
        RPTools.UI.CurrentTemplate = template.name
        stateIndicator:SetText("Template valid - you can now place a node in world. ")
      else
        RPTools.UI.CurrentParams = {}
        RPTools.UI.CurrentTemplate = ""
        stateIndicator:SetText("Template not valid - please fill the required parameters.")
      end
    end)
  end

  local function drawInfoPanel(node, panelX, panelTopY)
    local padding = 10
    local lineHeight = 20
    local headerHeight = 22
    local separatorHeight = 11

    local conditions = node.conditionsDesc or {}
    local actions = node.actionsDesc or {}

    local height = padding
      + headerHeight -- id/state
      + separatorHeight
      + lineHeight -- titre conditions
      + #conditions * lineHeight
      + separatorHeight
      + lineHeight -- titre actions
      + #actions * lineHeight
      + padding

    local x = panelX
    local y = panelTopY
    local w = 300

    draw.RoundedBox(8, x, y, w, height, Color(30, 30, 35, 200))

    local cursorY = y + padding

    draw.SimpleText(node.id, "DermaDefaultBold", x + padding, cursorY, color_white, TEXT_ALIGN_LEFT)
    draw.SimpleText(
      RPTools.Coordinator.stateText[node.state],
      "DermaDefault",
      x + w - padding,
      cursorY,
      RPTools.Coordinator.stateColor[node.state],
      TEXT_ALIGN_RIGHT
    )
    cursorY = cursorY + headerHeight

    cursorY = cursorY + 5
    surface.SetDrawColor(Color(80, 85, 95))
    surface.DrawRect(x + padding, cursorY, w - padding * 2, 1)
    cursorY = cursorY + 6

    draw.SimpleText("Conditions", "DermaDefaultBold", x + padding, cursorY, Color(200, 200, 200))
    cursorY = cursorY + lineHeight

    for _, desc in ipairs(conditions) do
      local text = string.sub(desc, 1, 40)
      if #desc > 40 then
        text = text .. "..."
      end
      draw.SimpleText(text, "DermaDefault", x + padding + 5, cursorY, Color(180, 180, 180))
      cursorY = cursorY + lineHeight
    end

    cursorY = cursorY + 5
    surface.SetDrawColor(Color(80, 85, 95))
    surface.DrawRect(x + padding, cursorY, w - padding * 2, 1)
    cursorY = cursorY + 6

    draw.SimpleText("Actions", "DermaDefaultBold", x + padding, cursorY, Color(200, 200, 200))
    cursorY = cursorY + lineHeight

    for _, desc in ipairs(actions) do
      local text = string.sub(desc, 1, 40)
      if #desc > 40 then
        text = text .. "..."
      end
      draw.SimpleText(text, "DermaDefault", x + padding + 5, cursorY, Color(180, 180, 180))
      cursorY = cursorY + lineHeight
    end
  end

  function TOOL:DrawHUD()
    if visibleNodeCache.lastCalculation == 0 or CurTime() - visibleNodeCache.lastCalculation > 0.2 then
      detectNodes()
    end

    if visibleNodeCache.length == 0 then
      return
    end

    local nodes = RPTools.Utilities.Map(visibleNodeCache.data, function(_, data)
      return data.node
    end)

    local height = 30 + #nodes * 25 + 25 + 20

    local x = ScrW() - 320
    local y = ScrH() * 0.35

    draw.RoundedBox(8, x, y, 300, height, Color(30, 30, 35, 200))
    draw.SimpleText(
      "Nearby nodes",
      "DermaDefaultBold",
      x + 150,
      y + 15,
      Color(255, 255, 255),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    for i, node in ipairs(nodes) do
      local pos = y + 30 + (i - 1) * 25

      local color = Color(120, 120, 120)
      if i == selectedIndex then
        color = color_white
      end

      draw.RoundedBox(4, x + 10, pos, 280, 22, Color(50, 53, 60, 150))

      if i == selectedIndex then
        draw.SimpleText("►", "DermaDefault", x + 15, pos + 11, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      end

      draw.SimpleText(node.id, "DermaDefault", x + 30, pos + 11, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      draw.SimpleText(
        RPTools.Coordinator.stateText[node.state],
        "DermaDefault",
        x + 280,
        pos + 11,
        RPTools.Coordinator.stateColor[node.state],
        TEXT_ALIGN_RIGHT,
        TEXT_ALIGN_CENTER
      )
    end

    local selectedNode = nodes[selectedIndex]

    drawInfoPanel(selectedNode, x, y + height + 8)

    return
  end
end

function TOOL:LeftClick(tr)
  if CLIENT then
    if RPTools.UI.CurrentTemplate == "" then
      notification.AddLegacy("Please configure a template first", NOTIFY_ERROR, 3)
      surface.PlaySound("buttons/button10.wav")
      return false
    end
    local name = RPTools.UI.CurrentTemplate
    local params = RPTools.UI.CurrentParams

    RPTools.Network.SendToServer(RPTools.Network.MSG_TYPE.CREATE_FROM_TEMPLATE, function()
      net.WriteString(name)
      net.WriteTable(params)
      net.WriteVector(tr.HitPos)
      net.WriteBool(tr.Entity ~= nil)
      if tr.Entity ~= nil then
        net.WriteEntity(tr.Entity)
      end
    end)
    return true
  end
  return true
end

function TOOL:RightClick(_)
  if CLIENT then
    if visibleNodeCache.length == 0 then
      return false
    end

    local node = visibleNodeCache.data[selectedIndex].node

    RPTools.Network.SendToServer(RPTools.Network.MSG_TYPE.DELETE_NODE, function()
      net.WriteString(node.id)
    end)

    notification.AddLegacy("Node " .. node.id .. " removed", NOTIFY_UNDO, 3)

    return true
  end
  return true
end

function TOOL:Reload(_)
  if CLIENT then
    selectedIndex = selectedIndex + 1
    if selectedIndex > visibleNodeCache.length then
      selectedIndex = 1
    end
    return true
  end
  return true
end

function TOOL:Holster()
  if CLIENT then
    if self.debugActive then
      LocalPlayer():ConCommand("rptools_toggle_debug")
      self.debugActive = false
    end
  end
end

function TOOL:Think()
  if CLIENT then
    if not self.debugActive then
      LocalPlayer():ConCommand("rptools_toggle_debug")
      self.debugActive = true
    end
  end
end
