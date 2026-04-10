RPTools = RPTools or {}
RPTools.Commands = RPTools.Commands or {}

local printToPlayer = RPTools.Commands.PrintToPlayer

local attrTable = "attributes"

concommand.Add("rptools_attr", function(ply, _, args, _)
  if not RPTools.Commands.requireAdmin(ply) then
    return
  end

  local name = args[1]

  if not name then
    printToPlayer(ply, "Please provide a player name")
    return
  end

  local target_players = RPTools.Utilities.FindPlayerByName(name)

  if table.IsEmpty(player) then
    printToPlayer(ply, "No player found for name " .. name)
  end

  local attribute = args[2]

  if not attribute then
    for _, target_player in ipairs(target_players) do
      local playerAttributes = RPTools.Blackboard.Read(target_player, attrTable)
      if not playerAttributes or table.IsEmpty(playerAttributes) then
        printToPlayer(ply, "Player " .. target_player:Nick() .. " has no attributes")
        continue
      end
      for attributeName, attributeValue in pairs(playerAttributes) do
        printToPlayer(ply, target_player:Nick() .. " (" .. attributeName .. ")" .. ": " .. tostring(attributeValue))
      end
    end
    return
  end

  local value = args[3]

  if not value then
    for _, target_player in ipairs(target_players) do
      local playerAttributes = RPTools.Blackboard.Read(target_player, attrTable)
      print(
        target_player:Nick()
          .. " ("
          .. attribute
          .. ")"
          .. ": "
          .. (playerAttributes ~= nil and tostring(playerAttributes[attribute]) or "not set")
      )
    end
  else
    local attributeValue = tonumber(value)
    if not attributeValue then
      printToPlayer(ply, "Value must be a valid number")
      return
    end

    for _, target_player in ipairs(target_players) do
      local playerAttributes = RPTools.Blackboard.Read(target_player, attrTable)
      local newAttributes = playerAttributes or {}
      newAttributes[attribute] = attributeValue
      RPTools.Blackboard.Write(target_player, attrTable, newAttributes)
      printToPlayer(ply, "Set attribute " .. attribute .. " for " .. target_player:Nick() .. " to " .. tostring(attributeValue))
    end
  end
end)
