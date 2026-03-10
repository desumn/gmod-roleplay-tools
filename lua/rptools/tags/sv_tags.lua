
RPTools.Tags = RPTools.Tags or {}
RPTools.Tags.tagRegister = RPTools.Tags.tagRegister or {}
RPTools.Tags.playerTags = RPTools.Tags.playerTags or {}

RPTools.Tags.error = {
    tagNotFound = 0;
    noPlayerTagTable = 1
}

function RPTools.Tags.formatTag(tagname)
    return string.lower(tagname)
end

function RPTools.Tags.newTag(tagname)
    RPTools.Tags.tagRegister[RPTools.Tags.formatTag(tagname)] = true
end

function RPTools.Tags.removeTag(tagname)
    RPTools.Tags.tagRegister[RPTools.Tags.formatTag(tagname)] = nil
end

function RPTools.Tags.tagExists(tagname)
    return RPTools.Tags.tagRegister[RPTools.Tags.formatTag(tagname)] or false
end

function RPTools.Tags.tagPlayer(ply, tagname)
    local formatted_tagname = RPTools.Tags.formatTag(tagname)
    local steamid = ply:SteamID64()

    if not RPTools.Tags.tagExists(formatted_tagname) then
        return false, RPTools.Tags.error.tagNotFound
    elseif not RPTools.Tags.playerTags[steamid] then
        return false, RPTools.Tags.error.noPlayerTagsTable
    else
        RPTools.Tags.playerTags[steamid][formatted_tagname] = true
        return true, nil
    end
end

function RPTools.Tags.untagPlayer(ply, tagname)
    local formatted_tagname = RPTools.Tags.formatTag(tagname)
    local steamid = ply:SteamID64()

    if not RPTools.Tags.tagExists(formatted_tagname) then
        return false, RPTools.Tags.error.tagNotFound
    elseif not RPTools.Tags.playerTags[steamid] then
        return false, RPTools.Tags.error.noPlayerTagsTable
    else
        RPTools.Tags.playerTags[steamid][formatted_tagname] = nil
        return true, nil
    end
end

function RPTools.Tags.playerTagged(ply, tagname)
    local steamid = ply:SteamID64()
    if not RPTools.Tags.playerTags[steamid] then
        return false
    else
        return RPTools.Tags.playerTags[ply:SteamID64()][RPTools.Tags.formatTag(tagname)] or false
    end
end

function RPTools.Tags.sendTagRegister(ply)
    net.Start("rptools_register_list")
    net.WriteTable(table.GetKeys(RPTools.Tags.tagRegister), true)
    net.Send(ply)
end

function RPTools.Tags.sendPlayerTags(ply, target)
    net.Start("rptools_player_tags")
    net.WritePlayer(target)
    net.WriteTable(table.GetKeys(RPTools.Tags.playerTags[target:SteamID64()] or {}), true)
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "RPTools_CreateTagTable", function (ply)

    local steamid = ply:SteamID64()
    RPTools.Tags.playerTags[steamid] = RPTools.Tags.playerTags[steamid] or {}
    print("[RPTools] Player " .. ply:Nick() .. "(" .. steamid .. ")" .. " tags initialized.")

end)

net.Receive("rptools_register_list", function (_, ply)
    if not ply:IsAdmin() then return end
    RPTools.Tags.sendTagRegister(ply)
end)

net.Receive("rptools_add_tag", function (_, ply)
    if not ply:IsAdmin() then return end
    RPTools.Tags.newTag(net.ReadString())
    RPTools.Tags.sendTagRegister(ply)
end)

net.Receive("rptools_remove_tag", function (_, ply)
    if not ply:IsAdmin() then return end
    RPTools.Tags.removeTag(net.ReadString())
    RPTools.Tags.sendTagRegister(ply)
end)


net.Receive("rptools_player_tags", function (_, ply)
    if not ply:IsAdmin() then return end
    local target = net.ReadPlayer()
    RPTools.Tags.sendPlayerTags(ply, target)
end)

net.Receive("rptools_tag_player", function (_, ply)
    if not ply:IsAdmin() then return end
    local tag = net.ReadString()
    local target = net.ReadPlayer()
    RPTools.Tags.tagPlayer(target, tag)
    RPTools.Tags.sendPlayerTags(ply, target)
end)

net.Receive("rptools_untag_player", function (_, ply)
    if not ply:IsAdmin() then return end
    local tag = net.ReadString()
    local target = net.ReadPlayer()
    RPTools.Tags.untagPlayer(target, tag)
    RPTools.Tags.sendPlayerTags(ply, target)
end)