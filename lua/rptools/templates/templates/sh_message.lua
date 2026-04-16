local param = RPTools.Templating.Parameters

RPTools.Templating.RegisterTemplate({
  name = "message",
  description = "send a message to the player, potentially mark him",
  parameters = {
    message = param.LongString("message", "message to send to the player"),
    useHUD = param.Boolean("Use HUD", "wheter to send the message through HUD", "action"),
    sendToChat = param.Boolean(
      "Send to chat",
      "if Use HUD is true: whether to send or not the message to chat, too.",
      "HUD Options"
    ),
    duration = param.Duration("Duration", "how long the message will be shwon (HUD only)", false, "HUD Options"),
    distance = param.Distance(),
    angle = param.Angle(),
    sight = param.CheckSight(),
    inFlag = param.ShortString("Input Flag", "Flag required for activation", false),
    invertInFlag = param.Boolean("Invert flag", "invert the input flag condition"),
    outFlag = param.ShortString("Output flag", "Flag that will be set to true", false, "action"),
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

    if args.inFlag ~= nil then
      local op = (args.invertInFlag and "ne") or "eq"
      local flag_cond = RPTools.Condition.Create("flag", args.inFlag, op, true)
      RPTools.Condition.AddToSet(conditions, flag_cond)
    end

    local actions = RPTools.Actions.Server.EmptyActionSet()

    if args.outFlag ~= nil then
      local action = RPTools.Actions.Server.Create("flag", { key = args.outFlag, value = true })
      RPTools.Actions.Server.AddToSet(actions, action)
    end

    local messageAction = RPTools.Actions.Server.Create("chat_message", { message = args.message })

    if args.useHUD then
      if args.sendToChat then
        RPTools.Actions.Server.AddToSet(actions, messageAction)
      end
      messageAction = RPTools.Actions.Server.Create("hud_message", { message = args.message, duration = args.duration })
    end

    RPTools.Actions.Server.AddToSet(actions, messageAction)

    local node = RPTools.Node.Create(context.position, conditions, actions, 0)
    return { node }
  end or nil,
})
