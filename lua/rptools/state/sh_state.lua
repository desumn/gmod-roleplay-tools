RPTools = RPTools or {}

---@enum RPToolsStateScope
local SCOPE = {
  PLAYER = 1,
  GLOBAL = 2,
}

RPTools.State = RPTools.State or {}
RPTools.State.Shared = {
  SCOPE = SCOPE,
}
