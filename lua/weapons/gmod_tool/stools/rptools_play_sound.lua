TOOL.Category = "RPTools"
TOOL.Name = "Play Sound"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
  sound = "",
  scope = "world",
  loop = "0",
  iterations = "0",
  volume = "1",
  pitch = "100",
  level = "75",
}

if SERVER then
  util.AddNetworkString("rptools_tool_play_sound")

  net.Receive("rptools_tool_play_sound", function(_, ply)
    local entIndex = net.ReadUInt(16)
    local add = net.ReadBool()
    local sound = net.ReadString()
    local scope = net.ReadString()
    local loop = net.ReadBool()
    local iterations = net.ReadUInt(10)
    local volume = net.ReadFloat()
    local pitch = net.ReadUInt(8)
    local level = net.ReadUInt(10)

    if not ply:IsAdmin() then
      return
    end

    local ent = Entity(entIndex)
    if ent:GetClass() ~= "ent_rptools_node" then
      return
    end
    ---@cast ent RPToolsNodeEntity

    if add then
      if scope == "player" then
        RPTools.Transformers.AddPlayPlayerSound(ent, sound, volume, pitch)
      elseif scope == "world" then
        if loop then
          RPTools.Transformers.AddLoopSound(ent, sound, iterations > 0 and iterations or nil, volume, pitch, level)
        else
          RPTools.Transformers.AddPlayWorldSound(ent, sound, volume, pitch, level)
        end
      end
    else
      -- Retire l'action correspondant aux paramètres courants
      local targetTarget = scope
      local targetAction = loop and "loop_sound" or "play_sound"

      local actionIndex = nil
      for i, action in ipairs(ent.actions) do
        if action.target == targetTarget and action.action == targetAction and action.sound == sound then
          actionIndex = i
          break
        end
      end

      if actionIndex then
        RPTools.Transformers.RemoveAction(ent, actionIndex)
      end
    end
  end)
end

local function writePacket(self, selectedIndex, add)
  net.Start("rptools_tool_play_sound")
  net.WriteUInt(selectedIndex, 16)
  net.WriteBool(add)
  net.WriteString(self:GetClientInfo("sound"))
  net.WriteString(self:GetClientInfo("scope"))
  net.WriteBool(self:GetClientBool("loop", false))
  net.WriteUInt(self:GetClientNumber("iterations", 0), 10)
  net.WriteFloat(self:GetClientNumber("volume", 1))
  net.WriteUInt(self:GetClientNumber("pitch", 100), 8)
  net.WriteUInt(self:GetClientNumber("level", 75), 10)
  net.SendToServer()
end

function TOOL:LeftClick(_)
  if CLIENT then
    local selectedIndex = RPTools.Inspector.GetSelectedEntIndex()
    if selectedIndex == nil then
      return
    end
    writePacket(self, selectedIndex, true)
    return true
  end
end

function TOOL:RightClick(_)
  if CLIENT then
    local selectedIndex = RPTools.Inspector.GetSelectedEntIndex()
    if selectedIndex == nil then
      return
    end
    writePacket(self, selectedIndex, false)
    return true
  end
end

function TOOL:Reload(_)
  if CLIENT then
    RPTools.Inspector.ClearSelection()
    return true
  end
end

function TOOL:Holster()
  if CLIENT then
    if self.debugActive then
      LocalPlayer():ConCommand("rptools_debug")
      self.debugActive = false
    end
  end
end

function TOOL:Think()
  if CLIENT then
    if not self.debugActive then
      LocalPlayer():ConCommand("rptools_debug")
      self.debugActive = true
    end
  end
end

if CLIENT then
  function TOOL:DrawToolScreen(width, height)
    surface.SetDrawColor(20, 20, 20, 255)
    surface.DrawRect(0, 0, width, height)

    local sound = self:GetClientInfo("sound")
    local scope = self:GetClientInfo("scope")
    local loop = self:GetClientBool("loop", false)

    local title = "Play Sound"
    if scope == "world" and loop then
      title = "Loop Sound"
    end

    draw.SimpleText(
      title,
      "DermaLarge",
      width / 2,
      height * 0.2,
      Color(180, 180, 180),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    local soundDisplay = sound == "" and "(no sound)" or sound
    if #soundDisplay > 28 then
      soundDisplay = "..." .. string.sub(soundDisplay, -25)
    end

    draw.SimpleText(
      soundDisplay,
      "DermaDefault",
      width / 2,
      height * 0.45,
      Color(240, 235, 230),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    local details = "scope: " .. scope
    draw.SimpleText(
      details,
      "DermaDefault",
      width / 2,
      height * 0.65,
      Color(180, 180, 180),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
      "Configure in menu",
      "DermaDefault",
      width / 2,
      height * 0.9,
      Color(120, 120, 120),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER
    )
  end

  ---@param panel DForm
  function TOOL.BuildCPanel(panel)
    panel:Help("Add a sound action to selected node.")

    panel:TextEntry("Sound path", "rptools_play_sound_sound")

    local playButton = panel:Button("Play")
    playButton.DoClick = function()
      local s = GetConVar("rptools_play_sound_sound"):GetString()
      if s == "" then
        return
      end
      local volume = GetConVar("rptools_play_sound_volume"):GetFloat()
      local pitch = GetConVar("rptools_play_sound_pitch"):GetInt()
      LocalPlayer():EmitSound(s, 0, pitch, volume)
    end

    local stopButton = panel:Button("Stop")
    stopButton.DoClick = function()
      local s = GetConVar("rptools_play_sound_sound"):GetString()
      if s ~= "" then
        LocalPlayer():StopSound(s)
      end
    end

    local scopeCombo = panel:ComboBox("Scope", "rptools_play_sound_scope")
    scopeCombo:AddChoice("World (spatial)", "world")
    scopeCombo:AddChoice("Player (client)", "player")

    local loopCheckbox = panel:CheckBox("Loop", "rptools_play_sound_loop")
    local iterationsSlider = panel:NumSlider("Iterations (0 = infinite)", "rptools_play_sound_iterations", 0, 100, 0)

    panel:NumSlider("Volume", "rptools_play_sound_volume", 0, 1, 2)
    panel:NumSlider("Pitch", "rptools_play_sound_pitch", 0, 255, 0)
    local levelSlider = panel:NumSlider("Level (world only)", "rptools_play_sound_level", 0, 511, 0)

    local function updateEnabled()
      local scope = GetConVar("rptools_play_sound_scope"):GetString()
      local loop = GetConVar("rptools_play_sound_loop"):GetBool()
      local isWorld = scope == "world"

      loopCheckbox:SetEnabled(isWorld)
      iterationsSlider:SetEnabled(isWorld and loop)
      levelSlider:SetEnabled(isWorld)
    end

    updateEnabled()

    cvars.AddChangeCallback("rptools_play_sound_scope", function()
      if IsValid(loopCheckbox) then
        updateEnabled()
      end
    end, "rptools_play_sound_scope_watcher")

    cvars.AddChangeCallback("rptools_play_sound_loop", function()
      if IsValid(loopCheckbox) then
        updateEnabled()
      end
    end, "rptools_play_sound_loop_watcher")
  end
end
