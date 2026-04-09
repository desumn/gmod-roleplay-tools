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

  RPTools.Save.LoadAll(name)
end)

concommand.Add("rptools_saves", function(ply, _, args, _)
  if not RPTools.Commands.requireAdmin(ply) then
    return
  end

  PrintTable(RPTools.Save.ListSave())
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

  RPTools.Save.Delete(name)
end)
