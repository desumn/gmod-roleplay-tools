local logModuleName = "Dispatcher"

RPTools = RPTools or {}

hook.Add("RPTools_NodeActivated", "rptools_dispatch_actions", function(node, players)
  local success, err = pcall(RPTools.Actions.Server.Execute, node.actions, players, node)
  if not success then
  end
end)

hook.Add("RPTools_PlayersActivation", "rptools_dispatch_actions_join", function(node, players)
  local success, err = pcall(RPTools.Actions.Server.Execute, node.actions, players, node)
  if not success then
  end
end)

hook.Add("RPTools_NodeDeactivated", "rptools_dispatch_stop", function(node)
  local success, err = pcall(RPTools.Actions.Server.StopContinuous, node)
  if not success then
  end
end)
