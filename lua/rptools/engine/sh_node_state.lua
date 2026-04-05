RPTools = RPTools or {}
RPTools.Coordinator = RPTools.Coordinator or {}


RPTools.Coordinator.NODE_STATE = {
    RUNNING = 1,
    ERROR = 2,
    PAUSED = 3,
}

RPTools.Coordinator.stateColor = {
    [RPTools.Coordinator.NODE_STATE.RUNNING] = Color(0, 140, 0),
    [RPTools.Coordinator.NODE_STATE.ERROR] = Color(160, 60, 60),
    [RPTools.Coordinator.NODE_STATE.PAUSED] = Color(150, 100, 100)
}

RPTools.Coordinator.stateText = {
    [RPTools.Coordinator.NODE_STATE.RUNNING] = "Running",
    [RPTools.Coordinator.NODE_STATE.ERROR] = "Error",
    [RPTools.Coordinator.NODE_STATE.PAUSED] = "Paused"
}
