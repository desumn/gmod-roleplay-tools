RPTools = RPTools or {}

---@param node RPToolsNodeEntity
local function activate(node)
  node.state.paused = false
end

---@param node RPToolsNodeEntity
local function deactivate(node)
  node.state.paused = true
end

---@param name string
---@param callback fun(node : RPToolsNodeEntity)
local function onCreate(name, callback)
  hook.Add("RPTools_NodeCreated", name, callback)
end

---@param name string
---@param callback fun(entIndex : number)
local function onRemove(name, callback)
  hook.Add("RPTools_NodeRemoved", name, callback)
end

---@param name string
---@param callback fun(node : RPToolsNodeEntity, players : Player[])
local function onActivated(name, callback)
  hook.Add("RPTools_NodeActivated", name, callback)
end

---@param name string
---@param callback fun(node : RPToolsNodeEntity)
local function onDeactivated(name, callback)
  hook.Add("RPTools_NodeDeactivated", name, callback)
end

---@param name string
---@param callback fun(node : RPToolsNodeEntity, players : Player[])
local function onPlayersActivation(name, callback)
  hook.Add("RPTools_PlayersActivation", name, callback)
end

---@param name string
---@param callback fun(node : RPToolsNodeEntity, players : Player[])
local function onPlayersDeactivation(name, callback)
  hook.Add("RPTools_PlayersDeactivations", name, callback)
end

---@param name string
---@param callback fun(node : RPToolsNodeEntity)
local function onStateChanged(name, callback)
  hook.Add("RPTools_NodeStateChanged", name, callback)
end

---@param name string
---@param callback fun(node : RPToolsNodeEntity)
local function onEdited(name, callback)
  hook.Add("RPTools_NodeEdited", name, callback)
end

RPTools.Node = {
  Activate = activate,
  Deactivate = deactivate,
  OnCreate = onCreate,
  OnRemove = onRemove,
  OnStateChanged = onStateChanged,
  OnActivation = onActivated,
  OnDeactivation = onDeactivated,
  OnPlayersActivation = onPlayersActivation,
  OnPlayersDeactivation = onPlayersDeactivation,
  OnEdited = onEdited,
}
