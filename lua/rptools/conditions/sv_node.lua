RPTools = RPTools or {}

---@param node RPToolsNodeEntity
local function activate(node)
    node.state.paused = false
end

---@param node RPToolsNodeEntity
local function deactivate(node)
    node.state.paused = true
end

RPTools.Node = {
    Activate = activate,
    Deactivate = deactivate
}