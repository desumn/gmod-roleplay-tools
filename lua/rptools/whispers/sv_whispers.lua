
RPTools.Whispers = RPTools.Whispers or {}
RPTools.Whispers.receivedWhispers = RPTools.Whispers.receivedWhispers or {}
RPTools.Whispers.Distance = 300
RPTools.Whispers.errors = {
    tagNotFound = 0;
}

function RPTools.Whispers.formatId(whisper_id)
    return whisper_id
end

function RPTools.Whispers.newWhisper(ent, whisper_id, text, required_tag)
    if not RPTools.Tags.tagExists(required_tag) then
        return nil, RPTools.Whispers.errors.tagNotFound
    end

    ent.RPTools = ent.RPTools or {}

    ent.RPTools.whispers = ent.RPTools.whispers or {} 

    ent.RPTools.whispers[RPTools.Whispers.formatId(whisper_id)] = {
        id = RPTools.Whispers.formatId(whisper_id);
        text = text;
        required_tag = RPTools.Tags.formatTag(required_tag);
    }
end

function RPTools.Whispers.removeWhisper(ent, id)

    ent.RPTools.whispers[RPTools.Whispers.formatId(id)] = nil

end

function RPTools.Whispers.setAsReceived(ply, whisper_id)
    local steamid = ply:SteamID64()
    if not RPTools.Whispers.receivedWhispers[steamid] then
        RPTools.Whispers.receivedWhispers[steamid] = {}
    end

    RPTools.Whispers.receivedWhispers[steamid][RPTools.Whispers.formatId(whisper_id)] = true
end

function RPTools.Whispers.playerHasReceived(ply, whisper_id)
    if not RPTools.Whispers.receivedWhispers[ply:SteamID64()] then
        return false
    else
        return RPTools.Whispers.receivedWhispers[ply:SteamID64()][RPTools.Whispers.formatId(whisper_id)] or false
    end
end

function RPTools.Whispers.getWhispersForPlayer(ply, ent)
    local valid_whispers_ids = {}
    if not ent.RPTools or not ent.RPTools.whispers then return valid_whispers_ids end

    for whisper_id, whisper_data in pairs(ent.RPTools.whispers) do
        if RPTools.Tags.playerTagged(ply, whisper_data.required_tag) then
            valid_whispers_ids[#valid_whispers_ids+1] = whisper_id
        end
    end

    return valid_whispers_ids

end

function RPTools.Whispers.generateWhisperID()
    return os.time() .. "-" .. math.random(1000, 9999)
end

timer.Create("RPTools_WhisperCheck", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local dir = ply:EyeAngles():Forward()

        local tr = util.TraceLine({
            start = ply:EyePos();
            endpos = ply:EyePos() + dir * RPTools.Whispers.Distance;
            filter = { ply }
        })

        if not tr.Entity or not tr.Entity:IsValid() then continue end

        local whisper_ids = RPTools.Whispers.getWhispersForPlayer(ply, tr.Entity)
        local unseen_whisper_ids = {}

        if table.IsEmpty(whisper_ids) then continue end

        for _, whisper_id in ipairs(whisper_ids) do
            if not RPTools.Whispers.playerHasReceived(ply, whisper_id) then
                unseen_whisper_ids[#unseen_whisper_ids+1] = whisper_id
            end
        end

        if table.IsEmpty(unseen_whisper_ids) then continue end

        local whispers = {}
        for _, whisper_id in ipairs(unseen_whisper_ids) do
            RPTools.Whispers.setAsReceived(ply, whisper_id)
            whispers[#whispers+1] = tr.Entity.RPTools.whispers[whisper_id]
        end

        net.Start("show_whispers")
        net.WriteTable(whispers, true)
        net.WriteEntity(tr.Entity)
        net.Send(ply)

    end
end)


net.Receive("rptools_add_whisper", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local ent = net.ReadEntity()
    local tag = net.ReadString()
    local text = net.ReadString()

    RPTools.Whispers.newWhisper(ent, RPTools.Whispers.generateWhisperID(), text, tag)

    net.Start("rptools_open_editor")
    net.WriteEntity(ent)
    net.WriteTable(ent.RPTools.whispers)
    net.Send(ply)

end)

net.Receive("rptools_remove_whisper", function(len, ply)
    if not ply:IsAdmin() then return end
    
    local ent = net.ReadEntity()
    local id = net.ReadString()
    
    RPTools.Whispers.removeWhisper(ent, id)
    net.Start("rptools_open_editor")
    net.WriteEntity(ent)
    net.WriteTable(ent.RPTools.whispers)
    net.Send(ply)

end)