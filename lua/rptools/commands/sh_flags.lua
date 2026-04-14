concommand.Add("rptools_flag", function(ply, cmd, args, argStr)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end
    local target = RPTools.Commands.Args.Player(ply, args[1])
    if not target or not IsValid(target) then
      return
    end
    local flagName = RPTools.Commands.Args.String(ply, args[2], "flag")
    if not flagName then
      return
    end

    RPTools.Blackboard.Write(target, RPTools.Blackboard.Key.Flag(flagName), true)
    RPTools.Commands.PrintToPlayer(ply, "Set flag " .. flagName .. " for player " .. target:Nick())
  end
end, function(cmd, _, args)
  if args[1] and not args[2] then
    return RPTools.Commands.CompletePlayers(cmd, args[1])
  end
  return {}
end)

concommand.Add("rptools_unflag", function(ply, cmd, args, argStr)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end
    local target = RPTools.Commands.Args.Player(ply, args[1])
    if not target or not IsValid(target) then
      return
    end
    local flagName = RPTools.Commands.Args.String(ply, args[2], "flag")
    if not flagName then
      return
    end

    RPTools.Blackboard.Write(target, RPTools.Blackboard.Key.Flag(flagName), false)
    RPTools.Commands.PrintToPlayer(ply, "Unset flag " .. flagName .. " for player " .. target:Nick())
  end
end, function(cmd, _, args)
  if args[1] and not args[2] then
    return RPTools.Commands.CompletePlayers(cmd, args[1])
  end
  return {}
end)

concommand.Add("rptools_listflags", function(ply, cmd, args, argStr)
  if CLIENT then
    return
  end

  if SERVER then
    if not RPTools.Commands.requireAdmin(ply) then
      return
    end
    local target = RPTools.Commands.Args.Player(ply, args[1])
    if not target or not IsValid(target) then
      return
    end
    local flags = RPTools.Blackboard.FindByPrefix(target, RPTools.Blackboard.Key.Flag())

    if not flags or table.IsEmpty(flags) then
      RPTools.Commands.PrintToPlayer(ply, "No flags found for player " .. target:Nick())
      return
    end

    RPTools.Commands.PrintToPlayer(ply, target:Nick() .. " flags:")
    for flag, value in pairs(flags) do
      local flagName = string.sub(flag, string.len(RPTools.Blackboard.Key.Flag()) + 2)
      RPTools.Commands.PrintToPlayer(ply, flagName .. " = " .. tostring(value))
    end
  end
end, function(cmd, _, args)
  if args[1] and not args[2] then
    return RPTools.Commands.CompletePlayers(cmd, args[1])
  end
  return {}
end)
