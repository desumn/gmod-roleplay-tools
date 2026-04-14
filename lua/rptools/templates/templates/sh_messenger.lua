local param = RPTools.Templating.Parameters

RPTools.Templating.RegisterTemplate({
  name = "messenger",
  description = "send a message to the player",
  parameters = {
    message = param.LongString("message", "message to send to the player"),
    distance = param.Distance(),
    angle = param.Angle(),
    sight = param.CheckSight(),
    flag = param.Flag(),
    invertInFlag = param.Boolean("Send to chat", "invert the input flag condition"),
  },
  transformer = SERVER and function(args, context)
    local conditions = RPTools.Condition.EmptyConditionSet()
    local distance_cond = RPTools.Condition.Create("distance", nil, "le", args.distance)

    RPTools.Condition.AddToSet(conditions, distance_cond)

    local angle_cond = RPTools.Condition.Create("view_angle", nil, "le", args.angle)
    RPTools.Condition.AddToSet(conditions, angle_cond)

    if args.sight then
      local los_cond = RPTools.Condition.Create("line_of_sight", nil, "eq", true)
      RPTools.Condition.AddToSet(conditions, los_cond)
    end

    if args.flag ~= nil then      
      local op = (args.invertInFlag and "ne") or "eq"
      local flag_cond = RPTools.Condition.Create("flag", args.flag, op, true)
      RPTools.Condition.AddToSet(conditions, flag_cond)
    end

    local action = RPTools.Actions.Server.Create("chat_message", { message = args.message })

    local actions = RPTools.Actions.Server.EmptyActionSet()
    RPTools.Actions.Server.AddToSet(actions, action)

    local node = RPTools.Node.Create(
      context.position,
      conditions,
      0,
      actions,
      RPTools.Node.TRIGGER_POLICY.ONE_SHOT,
      RPTools.Node.SCOPE.SINGLE_PLAYER,
      0
    )
    return { node }
  end or nil,
})
