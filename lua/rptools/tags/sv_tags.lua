
RPTools.Tags = RPTools.Tags or {}

RPTools.Tags.error = {
    tagNotFound = 0;
    noPlayerTagTable = 1
}

function RPTools.Tags.generateTagID()
    return "tag:" .. os.time() .. "-" .. math.random(1000, 9999)
end

local tagTemplate = {
    id = "_"; -- Unique id, internal usage
    name = "No Name";
    colour = function (alpha) return Color(180, 140, 255, alpha) end;
}

local tagRegister = {}

function RPTools.Tags.formatTag(tagname)
    return string.lower(tagname)
end

function RPTools.Tags.newTag(tagName, colour)

    if not isstring(tagName) then return end
    if not colour or not IsColor(colour) then return end

    local tag = table.Copy(tagTemplate)

    local incompleteTag = {
        id = RPTools.Tags.generateTagID();
        name = tagName;
        colour = colour;
    }

    table.Merge(tag, incompleteTag, true)

    tagRegister[tag.id] = tag
    hook.Run("RPTools_TagRegisterUpdated")

end

function RPTools.Tags.removeTag(tagId)
    tagRegister[tagId] = nil
    hook.Run("RPTools_TagRegisterUpdated")
end

function RPTools.Tags.tagExists(tagId)
    return tagRegister[tagId] or false
end

function RPTools.Tags.getAllTags()
    return table.Copy(tagRegister)
end

hook.Add("RPTools_TagRegisterUpdated", "RPTools_SendRegisterToAdmin", function()

    local admin_table = {}
    for _, player in ipairs(player.GetAll()) do
        if player:IsValid() and player:IsAdmin() then 
            table.insert(admin_table, player)
        end
    end

    if #admin_table > 0 then
        net.Start("rptools_register_list")
        net.WriteTable(RPTools.Tags.getAllTags())
        net.Send(admin_table)
    end
end)

net.Receive("rptools_register_list", function (_, ply)
    if not ply:IsAdmin() then return end
    net.Start("rptools_register_list")
    net.WriteTable(RPTools.Tags.getAllTags())
    net.Send(ply)
end)

function RPTools.Tags.tagPlayer(ply, tagId)
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

net.Receive("rptools_add_tag", function (_, ply)
    if not ply:IsAdmin() then return end
    RPTools.Tags.newTag(net.ReadString(), net.ReadColor())
end)

net.Receive("rptools_remove_tag", function (_, ply)
    if not ply:IsAdmin() then return end
    RPTools.Tags.removeTag(net.ReadString())
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

