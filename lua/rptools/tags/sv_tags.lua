
RPTools.Tags = RPTools.Tags or {}

RPTools.Tags.error = {
    tagNotFound = 0;
    noPlayerTagTable = 1
}

function RPTools.Tags.generateTagID()
    return "tag:" .. os.time() .. "-" .. math.random(1000, 9999)
end

local tagTemplate = {
    id = "_";
    name = "No Name";
    colour = Color(180, 140, 255);
    tag = RPTools.Tags.Type.default;
}

local tagRegister = {}

function RPTools.Tags.loadRegisterFromDB()
    tagRegister = {}
    local dbRegister = sql.Query([[SELECT * FROM rptools_tags;]])

    if not dbRegister then return end

    for _, dbTag in ipairs(dbRegister) do
            local tagID = dbTag.id
            local data = util.JSONToTable(dbTag.data)
            
            if not data then data = table.Copy(tagTemplate) end

            local colour = data.colour
            if colour then
                data.colour = Color(colour.r, colour.g, colour.b, colour.a)
            end

            local tag = table.Copy(tagTemplate)
            table.Merge(tag, data)
            tagRegister[tag.id] = tag
    end
    hook.Run("RPTools_TagRegisterUpdated")

end

function RPTools.Tags.newTag(tagName, colour, type)

    if not isstring(tagName) then return end
    if not colour or not IsColor(colour) then return end

    local tag = table.Copy(tagTemplate)

    local incompleteTag = {
        id = RPTools.Tags.generateTagID();
        name = tagName;
        colour = colour;
        type = type;
    }

    table.Merge(tag, incompleteTag)

    local data = util.TableToJSON(tag)
    sql.QueryTyped([[INSERT INTO rptools_tags (id, data) VALUES (?, ?);]], tag.id, data)

    RPTools.Tags.loadRegisterFromDB()
end

function RPTools.Tags.removeTag(tagId)
    sql.QueryTyped([[DELETE FROM rptools_tags WHERE id = ?]], tagId)
    RPTools.Tags.loadRegisterFromDB()
end

function RPTools.Tags.tagExists(tagId)
    return tagRegister[tagId] or false
end

function RPTools.Tags.getAllTags()
    return table.Copy(tagRegister)
end

function RPTools.Tags.getName(tagId)
    if not RPTools.Tags.tagExists(tagId) then return end

    return tagRegister[tagId]

end

function RPTools.Tags.getTagById(tagId)
    if not RPTools.Tags.tagExists(tagId) then return end
    return table.Copy(tagRegister[tagId])
end

function RPTools.Tags.findTagByName(tagName)
    local tagId = nil
    for _, tag in pairs(tagRegister) do
        if string.lower(tag.name) == string.lower(tagName) then
            tagId = tag.id
        end
    end
    return tagId
end

hook.Add("RPTools_TagRegisterUpdated", "RPTools_SendRegisterToAdmin", function()

    local admin_table = {}
    for _, player in ipairs(player.GetAll()) do
        if player:IsValid() and RPTools.CanAdmin(player) then 
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
    net.Start("rptools_register_list")
    net.WriteTable(RPTools.Tags.getAllTags())
    net.Send(ply)
end)

net.Receive("rptools_add_tag", function (_, ply)
    if not RPTools.CanAdmin(ply) then return end
    RPTools.Tags.newTag(net.ReadString(), net.ReadColor(), net.ReadUInt(8))
end)

net.Receive("rptools_remove_tag", function (_, ply)
    if not RPTools.CanAdmin(ply) then return end
    RPTools.Tags.removeTag(net.ReadString())
end)

local playerTags = {}


function RPTools.Tags.loadPlayerTagsFromDB(ply)
    if not ply:IsValid() then return end
    local steamid = ply:SteamID64()
    playerTags[steamid] = {}
    local tag_ids = sql.QueryTyped([[SELECT tagId FROM rptools_player_tags WHERE Steamid64 = ?]], steamid)

    if not tag_ids then return end

    for _, tagId in ipairs(tag_ids) do
        playerTags[steamid][tagId.tagId] = true
    end
    hook.Run("RPTools_PlayerTagsUpdated", ply)

end

function RPTools.Tags.tagPlayer(ply, tagId)


    if not ply:IsValid() then return end
    if not RPTools.Tags.tagExists(tagId) then return end

    local steamid = ply:SteamID64()

    sql.QueryTyped([[INSERT INTO rptools_player_tags (SteamID64, tagID) VALUES (?, ?)]], steamid, tagId)
    RPTools.Tags.loadPlayerTagsFromDB(ply)

end

function RPTools.Tags.untagPlayer(ply, tagId)

    if not ply:IsValid() then return end
    if not RPTools.Tags.tagExists(tagId) then return end

    local steamid = ply:SteamID64()

    sql.QueryTyped([[DELETE FROM rptools_player_tags WHERE SteamID64 = ? AND tagId = ?]], steamid, tagId)

    RPTools.Tags.loadPlayerTagsFromDB(ply)
end

function RPTools.Tags.playerTagged(ply, tagId)
    local steamid = ply:SteamID64()
    if not playerTags[steamid] then
        return false
    else
        return playerTags[ply:SteamID64()][tagId] or false
    end
end

function RPTools.Tags.sendPlayerTags(ply, target)
    net.Start("rptools_player_tags")
    net.WritePlayer(target)
    net.WriteTable(table.GetKeys(playerTags[target:SteamID64()] or {}), true)
    net.Send(ply)
end

function RPTools.Tags.clearPlayerTags(ply)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID64()
    sql.QueryTyped([[DELETE FROM rptools_player_tags WHERE SteamID64 = ?]], steamid)
    RPTools.Tags.loadPlayerTagsFromDB(ply)
end

function RPTools.Tags.clearAllPlayerTags()
    sql.Query([[DELETE FROM rptools_player_tags;]])

    for steamid, _ in pairs(playerTags) do
        playerTags[steamid] = {}
    end

    for _, target in ipairs(player.GetAll()) do
        hook.Run("RPTools_PlayerTagsUpdated", target)
    end

    print("[RPTools] All player tags have been cleared from the database.")
end

hook.Add("PlayerInitialSpawn", "RPTools_CreateTagTable", function (ply)

    RPTools.Tags.loadPlayerTagsFromDB(ply)

    local steamid = ply:SteamID64()
    print("[RPTools] Player " .. ply:Nick() .. "(" .. steamid .. ")" .. " tags initialized.")

end)

hook.Add("PlayerDisconnected", "RPTools_FreeTagTable", function (ply)
    local steamid = ply:SteamID64()
    playerTags[steamid] = nil
    print("[RPTools] Player " .. ply:Nick() .. "(" .. steamid .. ")" .. " tags cleared from memory.")
end)

hook.Add("RPTools_PlayerTagsUpdated", "RPTools_SendPlayerTagsToAdmin", function(target)

    local admin_table = {}
    for _, player in ipairs(player.GetAll()) do
        if player:IsValid() and RPTools.CanAdmin(player) then 
            table.insert(admin_table, player)
        end
    end

    if #admin_table > 0 then
        RPTools.Tags.sendPlayerTags(admin_table, target)
    end
end)

net.Receive("rptools_player_tags", function (_, ply)
    if not RPTools.CanAdmin(ply) then return end
    local target = net.ReadPlayer()
    RPTools.Tags.sendPlayerTags(ply, target)
end)

net.Receive("rptools_tag_player", function (_, ply)
    if not RPTools.CanAdmin(ply) then return end
    local tag = net.ReadString()
    local target = net.ReadPlayer()
    RPTools.Tags.tagPlayer(target, tag)
end)

net.Receive("rptools_untag_player", function (_, ply)
    if not RPTools.CanAdmin(ply) then return end
    local tag = net.ReadString()
    local target = net.ReadPlayer()
    RPTools.Tags.untagPlayer(target, tag)
end)

net.Receive("rptools_nuke_player_tags", function(len, ply)
    if not RPTools.CanAdmin(ply) then return end
    RPTools.Tags.clearAllPlayerTags()

    ply:ChatPrint("[RPTools] Players tags nuked.")
end)

net.Receive("rptools_clear_player_tags", function(len, ply)
    if not RPTools.CanAdmin(ply) then return end
    local target = net.ReadEntity()
    RPTools.Tags.clearPlayerTags(target)
end)