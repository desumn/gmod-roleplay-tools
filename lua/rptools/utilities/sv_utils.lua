

RPTools.Utilities = RPTools.Utilities or {}

RPTools.Utilities.error = {
    playerNotFound = 0;
    multiplePlayersFound = 1;
}

function RPTools.Utilities.findPlayer(name)

    local target_name = string.Trim(string.lower(name), ' ')

    local candidate = {}

    for _, ply in ipairs(player.GetAll()) do
        local player_name = string.lower(ply:Nick())

        if ply:SteamID64() == target_name then return ply end

        if string.find(string.lower(ply:Nick()), target_name) then
            candidate[#candidate+1] = ply
        end
    end

    if #candidate == 0 then 
        return nil, RPTools.Utilities.error.playerNotFound
    elseif #candidate > 1 then
        return candidate, RPTools.Utilities.error.multiplePlayersFound
    else
        return candidate[1], nil
    end
end

function RPTools.Utilities.logToPlayer(ply, message)
    if ply:IsValid() then
        ply:ChatPrint("[RPTools] " .. message)
    else
        print("[RPTools]" .. message)
    end
end