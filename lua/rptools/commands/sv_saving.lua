RPTools = RPTools or {}
RPTools.Commands = RPTools.Commands or {}

concommand.Add("rptools_save", function(ply, _, args, _)
  if not RPTools.Commands.requireAdmin(ply) then
    return
  end

  local name = args[1]

  if not name then
    print("Please provide a save name")
    return
  end

  RPTools.Save.SaveAll(name)
  print("Successfully saved " .. name)
end)

concommand.Add("rptools_load", function(ply, _, args, _)
  if not RPTools.Commands.requireAdmin(ply) then
    return
  end

  local name = args[1]

  if not name then
    print("Please provide a save name")
    return
  end

  local loadSuccess = RPTools.Save.LoadAll(name)
  if not loadSuccess then
    print("Failed to load save " .. name .. " (do not include the .json extension in the name!)")
  else
    print("Successfully loaded save " .. name)  
  end
end)

concommand.Add("rptools_saves", function(ply, _, args, _)
  if not RPTools.Commands.requireAdmin(ply) then
    return
  end

  local saves = RPTools.Save.ListSaves()
  print("Saves: ")
  for _, savename in pairs(saves) do
    print("  " .. savename)
  end
end)

concommand.Add("rptools_delete_save", function(ply, _, args, _)
  if not RPTools.Commands.requireAdmin(ply) then
    return
  end

  local name = args[1]

  if not name then
    print("Please provide a save name")
    return
  end

  local deletionSuccess = RPTools.Save.Delete(name)

  if not deletionSuccess then
    print("Failed to delete save " .. name .. ", does it exists?")
  else
    print("Successfully deleted save " .. name)
  end
end)
