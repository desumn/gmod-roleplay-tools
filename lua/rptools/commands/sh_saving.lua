RPTools = RPTools or {}
RPTools.Commands = RPTools.Commands or {}

local printToPlayer = RPTools.Commands.PrintToPlayer

concommand.Add("rptools_save", function(ply, _, args, _)
  if CLIENT then
    return
  end
  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end

    local name = args[1]

    if not name then
      printToPlayer(ply, "Please provide a save name")
      return
    end

    RPTools.Save.SaveAll(name)
    printToPlayer(ply, "Successfully saved " .. name)
  end
end)

local function completeSaves(cmd, term)
  local candidates = {}
  local saves = RPTools.Save.ListSaves()
  for _, savename in pairs(saves) do
    if term == nil or string.StartsWith(savename, term) then
      table.insert(candidates, cmd .. " " .. string.sub(savename, 1, -6))
    end
  end
  return candidates
end

concommand.Add("rptools_load", function(ply, _, args, _)
  if CLIENT then
    return
  end
  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end

    local name = args[1]

    if not name then
      printToPlayer(ply, "Please provide a save name")
      return
    end

    local loadSuccess = RPTools.Save.LoadAll(name)
    if not loadSuccess then
      printToPlayer(ply, "Failed to load save " .. name .. " (do not include the .json extension in the name!)")
    else
      printToPlayer(ply, "Successfully loaded save " .. name)
    end
  end
end, function(cmd, argStr, args)
  local lastChar = string.sub(argStr, -1)
  if (args[1] and not args[2] and lastChar ~= " ") or (not args[1] and lastChar == " ") then
    return completeSaves(cmd, args[1])
  end
end)

concommand.Add("rptools_saves", function(ply, _, args, _)
  if CLIENT then
    return
  end
  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end

    local saves = RPTools.Save.ListSaves()
    print("Saves: ")
    for _, savename in pairs(saves) do
      printToPlayer(ply, "  " .. savename)
    end
  end
end)

concommand.Add("rptools_delete_save", function(ply, _, args, _)
  if CLIENT then
    return
  end
  if not RPTools.Commands.requireAdmin(ply) then
    return
  end
  if SERVER then
    local name = args[1]

    if not name then
      printToPlayer(ply, "Please provide a save name")
      return
    end

    local deletionSuccess = RPTools.Save.Delete(name)

    if not deletionSuccess then
      printToPlayer(ply, "Failed to delete save " .. name .. ", does it exists?")
    else
      printToPlayer(ply, "Successfully deleted save " .. name)
    end
  end
end, function(cmd, argStr, args)
  local lastChar = string.sub(argStr, -1)
  if (args[1] and not args[2] and lastChar ~= " ") or (not args[1] and lastChar == " ") then
    return completeSaves(cmd, args[1])
  end
end)
