RPTools = RPTools or {}
RPTools.Commands = RPTools.Commands or {}

RPTools.Commands.Args = RPTools.Commands.Args or {}

---@param ply Player
---@param string string
function RPTools.Commands.PrintToPlayer(ply, string)
  if not IsValid(ply) then
    print(string)
    return
  end
  RPTools.Network.SendToPlayer(ply, RPTools.Network.MSG_TYPE.PRINT, function()
    net.WriteString(string)
  end)
end

function RPTools.Commands.Args.Player(caller, name)
  if name == nil or not (isstring(name)) or name == "" then
    RPTools.Commands.PrintToPlayer(caller, "Please provide a player name")
    return
  end

  local foundPlayers = {}
  for _, ply in player.Iterator() do
    local lowerName = string.lower(ply:Nick())
    local lowerTargetName = string.lower(name)

    if lowerName == lowerTargetName then
      return ply
    end

    if string.find(lowerName, lowerTargetName, 1, true) then
      table.insert(foundPlayers, ply)
    end
  end

  if #foundPlayers == 0 then
    RPTools.Commands.PrintToPlayer(caller, "Player " .. name .. " not found")
    return
  end

  if #foundPlayers > 1 then
    local nicks = foundPlayers[1]:Nick()
    for idx, ply in ipairs(foundPlayers) do
      if idx == 1 then
        continue
      end
      nicks = ply:Nick() .. ", " .. nicks
    end
    RPTools.Commands.PrintToPlayer(caller, "Found multiple players: " .. nicks)
    return
  end

  return foundPlayers[1]
end

function RPTools.Commands.Args.String(caller, str, label, optional, default)
  local safeOptional = optional or false
  if not safeOptional and (str == nil or not isstring(str) or str == "") then
    RPTools.Commands.PrintToPlayer(caller, (label or "") .. ": Please provide a valid string")
    return
  end
  if safeOptional and str == nil then
    return default
  end
  return str
end

function RPTools.Commands.Args.Number(caller, num, label, optional, default)
  local safeOptional = optional or false
  if not safeOptional and (num == nil or not RPTools.Utilities.IsNumber(tonumber(num))) then
    RPTools.Commands.PrintToPlayer(caller, (label or "") .. ": Please provide a valid number")
    return
  end
  if safeOptional and num == nil then
    return default
  end
  return tonumber(num)
end

function RPTools.Commands.CompletePlayers(cmd, name)
  local foundPlayers = {}
  for _, ply in player.Iterator() do
    local lowerName = string.lower(ply:Nick())
    local lowerTargetName = (name and string.lower(name)) or ""

    if string.find(lowerName, lowerTargetName, 1, true) then
      table.insert(foundPlayers, cmd .. " " .. ply:Nick())
    end
  end
  return foundPlayers
end

function RPTools.Commands.CompleteBlackboardByPrefix(name, prefix)
  local target = nil

  local foundPlayers = {}
  for _, ply in player.Iterator() do
    local lowerName = string.lower(ply:Nick())
    local lowerTargetName = string.lower(name)

    if lowerName == lowerTargetName then
      ply = ply
      break
    end

    if string.find(lowerName, lowerTargetName, 1, true) then
      table.insert(foundPlayers, ply)
    end
  end

  if #foundPlayers == 0 then
    return {}
  end

  if #foundPlayers > 1 then
    return {}
  end

  local flags = RPTools.Blackboard.FindByPrefix(target, prefix)
  print("t")
  return (not flags == nil and not table.IsEmpty(flags) and table.GetKeys(flags)) or {}
end

if CLIENT then
  RPTools.Network.OnServerMessage(RPTools.Network.MSG_TYPE.PRINT, function()
    local string = net.ReadString()
    print(string)
  end)
end

local printToPlayer = RPTools.Commands.PrintToPlayer

function RPTools.Commands.requireAdmin(ply)
  if not IsValid(ply) then
    return true
  end
  if not ply:IsAdmin() then
    printToPlayer(ply, "Permission denied")
    return false
  else
    return true
  end
end

local coordinatorStarted = false

concommand.Add("rptools_start", function (ply)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end

    if coordinatorStarted then
      RPTools.Commands.PrintToPlayer(ply, "Coordinator is already started!")
      return
    end

    RPTools.Coordinator.Start()
    RPTools.Commands.PrintToPlayer(ply, "Started coordinator!")
  end
end)

concommand.Add("rptools_stop", function (ply)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end

    if not coordinatorStarted then
      RPTools.Commands.PrintToPlayer(ply, "Coordinator is not yet started!")
      return
    end

    RPTools.Coordinator.Stop()
    RPTools.Commands.PrintToPlayer(ply, "Stopped coordinator!")
  end
end)

concommand.Add("rptools_stop", function (ply)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end
    
    if not coordinatorStarted then
      RPTools.Commands.PrintToPlayer(ply, "Coordinator off.")
      return
    else
      RPTools.Commands.PrintToPlayer(ply, "Coordinator on.")
      return
    end
  end
end)

concommand.Add("rptools_vanish", function(ply)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then return end
    local currentValue = ply:GetNW2Bool("rptools_vanish")
    if currentValue then
      printToPlayer(ply, "You are already vanished.")
      return
    end
    ply:SetNW2Bool("rptools_vanish", true)
    printToPlayer(ply, "You vanished, you'll not be able to activate nodes.")
  end
end)

concommand.Add("rptools_unvanish", function(ply)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then return end
    local currentValue = ply:GetNW2Bool("rptools_vanish")
    if not currentValue then
      printToPlayer(ply, "You are not vanished!")
      return
    end
    ply:SetNW2Bool("rptools_vanish", false)
    printToPlayer(ply, "You're now visible again.")
  end
end)

