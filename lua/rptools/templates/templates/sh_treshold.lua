local param = RPTools.Templating.Parameters

RPTools.Templating.RegisterTemplate({
  name = "treshold",
  description = "check for a numeric flag, if it's over the treshold set a boolean flag",
  parameters = {
    distance = param.Distance(),
    treshold = param.Number("Treshold", "required treshold", nil, nil, true, nil, "trigger"),
    inCounter = param.ShortString("Counter name", "Counter name", true),
    outFlag = param.ShortString("Flag name", "Flag that will be set to true", true, "action"),
  },
  transformer = SERVER and function(args, context)
    local conditions = RPTools.Condition.EmptyConditionSet()
    local distance_cond = RPTools.Condition.Create("distance", nil, "le", args.distance)

    RPTools.Condition.AddToSet(conditions, distance_cond)

    local flag_cond = RPTools.Condition.Create("counter", args.inCounter, "ge", args.treshold)
    RPTools.Condition.AddToSet(conditions, flag_cond)

    local action = RPTools.Actions.Server.Create("flag", { key = args.outFlag, value = true })

    local actions = RPTools.Actions.Server.EmptyActionSet()
    RPTools.Actions.Server.AddToSet(actions, action)

    local node = RPTools.Node.Create(context.position, conditions, actions, 0)
    return { node }
  end or nil,
})
