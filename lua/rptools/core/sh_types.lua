-- Data structures
 
---@class RPToolsNode
---@field id string Unique identifier, auto-generated
---@field position Vector World position of the node
---@field conditions RPToolsCondition[] All conditions must be true (AND)
---@field requiredTime number Seconds conditions must hold before activation
---@field actions RPToolsAction[] Actions to execute on activation
---@field triggerPolicy RPToolsTriggerPolicy How the node reactivates
---@field scope RPToolsScope Player scope for evaluation
---@field priority number Higher priority nodes are evaluated first
---@field cooldownDuration number Seconds before reactivation (COOLDOWN only)
 
---@class RPToolsCondition
---@field source string Source function identifier ("distance", "flag")
---@field sourceParameter any Parameter passed to the source function (nil for distance, flag key for flag)
---@field operator string Operator identifier ("lt", "gt", "eq", "ne", "le", "ge", "between", "one_of")
---@field value any Value to compare against
 
---@class RPToolsAction
---@field actionType string Action type identifier ("chat_message", "flag")
---@field params table Parameters specific to the action type
 
-- Template structures
 
---@class RPToolsTemplate
---@field name string Unique template identifier
---@field description string Human-readable description for the UI
---@field parameters RPToolsParameter[] Declared parameters
---@field transformer fun(args: table, context: RPToolsContext): RPToolsNode[]|nil Builds nodes from validated arguments
 
---@class RPToolsParameter
---@field name string Parameter identifier
---@field description string Human-readable description
---@field type string Value type: "string", "number", or "boolean"
---@field display? string UI widget hint: "short", "long" (string only)
---@field required boolean Whether the parameter must be provided
---@field default? any Default value if not provided
 
---@class RPToolsContext
---@field position Vector World position for node placement
 
-- Coordinator structures
 
---@class RPToolsPlayerNodeState
---@field wasActivated boolean Whether the node has ever been activated for this player
---@field isActive boolean Whether the node is currently active (CONTINOUS)
---@field timer number Accumulated time with conditions met
---@field lastActivationTime number CurTime() of last activation
 
---@class RPToolsEvaluationContext
---@field ply Player The player being evaluated
---@field node RPToolsNode The node being evaluated
---@field nodeId string Node identifier
---@field state RPToolsPlayerNodeState Reference to the player-node state
---@field filtered boolean Whether this context should be skipped
---@field conditionsMet? boolean Result of condition evaluation
---@field timerReached? boolean Whether the required time has been reached
---@field shouldActivate? boolean Whether the node should activate this tick
---@field shouldDeactivate? boolean Whether the node should deactivate this tick (CONTINOUS)
---@field actionsToExecute? RPToolsAction[] Actions collected for execution
 
-- Debug structures
 
---@class RPToolsDebugNode
---@field id string Node identifier
---@field position Vector World position
---@field distance number Detection distance (from distance conditions)
---@field state RPToolsNodeState Current running state
 
-- Network
 
---@class RPToolsLog
---@field level RPToolsLogLevel
---@field curtime number CurTime() when logged
---@field date osdate Date table from os.date
---@field source string Module name
---@field message string Log message
 