local param = RPTools.Templating.Parameters

RPTools.Templating.RegisterTemplate({
  name = "counter",
  description = "increment a counter associated with the player",
  parameters = {
    distance = param.Distance(),
    step = param.Number("Step", "how much the counter is incremented, may be negative", nil, nil, true, 1, "action"),
    inFlag = param.ShortString("Input Flag", "Flag required for activation", false),
    invertInFlag = param.Boolean("Send to chat", "invert the input flag condition"),
    outCounter = param.ShortString("Counter name", "Counter that will be incremented", true, "action"),
  },
  transformer = SERVER and function(args, context)
    local conditions = RPTools.Condition.EmptyConditionSet()
    local distance_cond = RPTools.Condition.Create("distance", nil, "le", args.distance)

    RPTools.Condition.AddToSet(conditions, distance_cond)

    if args.inFlag ~= nil then
      local op = (args.invertInFlag and "ne") or "eq"
      local flag_cond = RPTools.Condition.Create("flag", args.inFlag, op, true)
      RPTools.Condition.AddToSet(conditions, flag_cond)
    end

    local action = RPTools.Actions.Server.Create("increment", { key = args.outCounter, value = args.step })

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
