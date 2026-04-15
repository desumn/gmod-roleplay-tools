concommand.Add("rptools_increment", function(ply, cmd, args, argStr)
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
    local counterName = RPTools.Commands.Args.String(ply, args[2], "counter")
    if not counterName then
      return
    end
    local step = RPTools.Commands.Args.Number(ply, args[3], "step", true, 1)

    RPTools.Blackboard.Increment(target, RPTools.Blackboard.Key.Counter(counterName), step)
    RPTools.Commands.PrintToPlayer(
      ply,
      "Incremented " .. counterName .. " for player " .. target:Nick() .. " by " .. tonumber(step)
    )
  end
end, function(cmd, argStr, args)
  local lastChar = string.sub(argStr, -1)
  if args[1] and not args[2] and lastChar ~= " " then
    return RPTools.Commands.CompletePlayers(cmd, args[1])
  end
  if (args[1] and args[2] and not args[3] and lastChar ~= " ") or (args[1] and not args[2] and lastChar == " ") then
    return RPTools.Commands.CompleteBlackboardByKey(cmd .. " " .. args[1], RPTools.Blackboard.Key.Counter(), args[2])
  end
  return {}
end)

concommand.Add("rptools_reset_counter", function(ply, cmd, args, argStr)
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
    local counterName = RPTools.Commands.Args.String(ply, args[2], "flag")
    if not counterName then
      return
    end

    RPTools.Blackboard.Write(target, RPTools.Blackboard.Key.Counter(counterName), 0)
    RPTools.Commands.PrintToPlayer(ply, "Reset counter " .. counterName .. " for player " .. target:Nick())
  end
end, function(cmd, argStr, args)
  local lastChar = string.sub(argStr, -1)
  if args[1] and not args[2] and lastChar ~= " " then
    return RPTools.Commands.CompletePlayers(cmd, args[1])
  end
  if (args[1] and args[2] and not args[3] and lastChar ~= " ") or (args[1] and not args[2] and lastChar == " ") then
    return RPTools.Commands.CompleteBlackboardByKey(cmd .. " " .. args[1], RPTools.Blackboard.Key.Flag(), args[2])
  end
  return {}
end)

concommand.Add("rptools_listcounters", function(ply, cmd, args, argStr)
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
    local flags = RPTools.Blackboard.FindByPrefix(target, RPTools.Blackboard.Key.Counter())

    if not flags or table.IsEmpty(flags) then
      RPTools.Commands.PrintToPlayer(ply, "No counter found for player " .. ply:Nick())
      return
    end

    RPTools.Commands.PrintToPlayer(ply, ply:Nick() .. " counters:")
    for flag, value in pairs(flags) do
      local flagName = RPTools.Blackboard.ExtractName(flag, RPTools.Blackboard.Key.Counter())
      RPTools.Commands.PrintToPlayer(ply, flagName .. " = " .. tostring(value))
    end
  end
end, function(cmd, _, args)
  if args[1] and not args[2] then
    return RPTools.Commands.CompletePlayers(cmd, args[1])
  end
  return {}
end)
