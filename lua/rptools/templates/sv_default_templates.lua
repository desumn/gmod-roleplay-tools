RPTools = RPTools or {}

RPTools.Templating.RegisterTemplate({
    name = "messager",
    description = "Node that send a chat message once to a neraby player eventually checking for player flags",
    parameters = {
        {
            name = "message",
            description = "message to send",
            type = "string",
            required = true
        },
        {
            name = "distance",
            description = "activation distance",
            type = "number",
            required = true,
            default = 200
        },
        {
            name = "flag",
            description = "required flag for activating",
            type = "string",
            required = false
        }
    },
    transformer = function (args, context)
        
        local distance_cond = RPTools.Condition.Create("distance", nil, "le", args.distance)

        local conditions = RPTools.Condition.EmptyConditionSet()
        RPTools.Condition.AddToSet(conditions, distance_cond)

        if args.flag ~= nil then
            local flag_cond = RPTools.Condition.Create("flag", args.flag, "eq", true)
            RPTools.Condition.AddToSet(conditions, flag_cond)
        end

        local action = RPTools.Actions.Create("chat_message", { message = args.message })
        
        local actions = RPTools.Actions.EmptyActionSet()
        RPTools.Actions.AddToSet(actions, action)
        
        local node = RPTools.Node.Create(context.position, conditions, 0, actions, RPTools.Node.TRIGGER_POLICY.ONE_SHOT, RPTools.Node.SCOPE.SINGLE_PLAYER, 0)
        
        return {node}
    end
})