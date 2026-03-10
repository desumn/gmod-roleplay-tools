
concommand.Add("rptools_new_tag", function (ply, _, args, _)
    if CLIENT then return end

    if ply:IsValid() and not ply:IsAdmin() then return end

    local tag = args[1]

    if not tag then
        RPTools.Utilities.logToPlayer(ply, "Usage: rptools_new_tag [tag]")
    end

    RPTools.Tags.newTag(tag)

    RPTools.Utilities.logToPlayer(ply, "Added tag " .. RPTools.Tags.formatTag(tag))

end)

concommand.Add("rptools_remove_tag", function (ply, _, args, _)
    if CLIENT then return end

    if ply:IsValid() and not ply:IsAdmin() then return end

    local tag = args[1]

    if not tag then
        RPTools.Utilities.logToPlayer(ply, "Usage: rptools_remove_tag [tag]")
    end

    RPTools.Tags.removeTag(tag)

    RPTools.Utilities.logToPlayer("Removed tag " .. RPTools.Tags.formatTag(tag))


end)

concommand.Add("rptools_tag_register", function (ply, _, args, _)
    if CLIENT then return end

    if ply:IsValid() and not ply:IsAdmin() then return end

    local tableString = table.ToString(RPTools.Tags.tagRegister)

    RPTools.Utilities.logToPlayer(ply, tableString)

end)

concommand.Add("rptools_tag", function (ply, _, args, _)
    if CLIENT then return end

    if ply:IsValid() and not ply:IsAdmin() then return end

    local playerName = args[1]
    local tag = args[2]

    if not tag then
        RPTools.Utilities.logToPlayer(ply, "Usage: rptools_tag [player] [tag]")
        return
    end

    if not RPTools.Tags.tagExists(tag) then
        RPTools.Utilities.logToPlayer(ply, "Tag " .. RPTools.Tags.formatTag(args[2]) .. " does not exists")
        return
    end

    local target, err = RPTools.Utilities.findPlayer(playerName)

    if err == RPTools.Utilities.error.playerNotFound then
        RPTools.Utilities.logToPlayer(ply, "Player " .. playerName .. "not found")
    elseif err == RPTools.Utilities.error.multiplePlayersFound then
        local names = table.concat(target, ", ")
        RPTools.Utilities.logToPlayer(ply, "Multiple players (" .. names .. ") found")
    else
        RPTools.Tags.tagPlayer(target, tag)
        RPTools.Utilities.logToPlayer(ply, "Tag " .. RPTools.Tags.formatTag(tag) .. " added to " .. target:Nick())
    end
end)

concommand.Add("rptools_untag", function (ply, _, args, _)
    if CLIENT then return end

    if ply:IsValid() and not ply:IsAdmin() then return end

    local playerName = args[1]
    local tag = args[2]

    if not tag then
        RPTools.Utilities.logToPlayer(ply, "Usage: rptools_untag [player] [tag]")
        return
    end

    if not RPTools.Tags.tagExists(tag) then
        RPTools.Utilities.logToPlayer(ply, "Tag " .. RPTools.Tags.formatTag(tag) .. " doesn't exist")
        return
    end

    local target, err = RPTools.Utilities.findPlayer(playerName)

    if err == RPTools.Utilities.error.playerNotFound then
        RPTools.Utilities.logToPlayer(ply, "Player " .. playerName .. "not found")
    elseif err == RPTools.Utilities.error.multiplePlayersFound then
        local names = table.concat(target, ", ")
        RPTools.Utilities.logToPlayer(ply, "Multiple players (" .. names .. ") found")
    else
        RPTools.Tags.untagPlayer(target, tag)
        RPTools.Utilities.logToPlayer(ply, "Tag " .. RPTools.Tags.formatTag(tag) .. " removed from " .. target:Nick())
    end
end)

concommand.Add("rptools_show_tags", function (ply, _, args, _)
    if CLIENT then return end

    if ply:IsValid() and not ply:IsAdmin() then return end

    local playerName = args[1]

    local target, err = RPTools.Utilities.findPlayer(args[1])

    if err == RPTools.Utilities.error.playerNotFound then
        RPTools.Utilities.logToPlayer(ply, "Player " .. playerName .. "not found")
    elseif err == RPTools.Utilities.error.multiplePlayersFound then
        local names = table.concat(target, ", ")
        RPTools.Utilities.logToPlayer(ply, "Multiple players (" .. names .. ") found")
    else
        if not RPTools.Tags.playerTags[target:SteamID64()] then
            RPTools.Utilities.logToPlayer(ply, "Player " .. target:Nick() .. " has no tag table")
        else
            RPTools.Utilities.logToPlayer(ply, target:Nick() .. " tags: " ..
                                               table.ToString(table.GetKeys(RPTools.Tags.playerTags[target:SteamID64()])))
        end
    end
end)

concommand.Add("rptools_create_whispers", function (ply, _, args, _)
    if CLIENT then return end

    if not ply:IsValid() and not ply:IsAdmin() then return end

    if not args[3] then return end


    local whisper_id = args[1]
    local tag = args[2]
    local description = args[3]


    if not RPTools.Tags.tagExists(tag) then
        RPTools.Utilities.logToPlayer(ply, "Tag " .. RPTools.Tags.formatTag(tag) .. " not found")
        return
    end

    local ent = ply:GetEyeTrace().Entity

    if not ent then return end

    RPTools.Whispers.newWhisper(ent, whisper_id, description, tag)

    RPTools.Utilities.logToPlayer("Whisper added")

end)


concommand.Add("rptools_show_whispers", function (ply, _, args, _)
    if CLIENT then return end

    if not ply:IsValid() or not ply:IsAdmin() then return end

    local ent = ply:GetEyeTrace().Entity

    if not ent then return end
    if not ent.RPTools then return end
    
    PrintTable(ent.RPTools.whispers)

end)


concommand.Add("rptools_clear_whisper_memory", function (ply, _, args, _)
    if CLIENT then return end

    if ply:IsValid() and not ply:IsAdmin() then return end

    local playerName = args[1]

    local target, err = RPTools.Utilities.findPlayer(args[1])

    if err == RPTools.Utilities.error.playerNotFound then
        RPTools.Utilities.logToPlayer(ply, "Player " .. playerName .. "not found")
    elseif err == RPTools.Utilities.error.multiplePlayersFound then
        local names = table.concat(target, ", ")
        RPTools.Utilities.logToPlayer(ply, "Multiple players (" .. names .. ") found")
    else
        RPTools.Whispers.receivedWhispers[ply:SteamID64()] = nil
    end
end)


