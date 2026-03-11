
RPTools.Whispers = RPTools.Whispers or {}
RPTools.Whispers.receivedWhispers = RPTools.Whispers.receivedWhispers or {}
RPTools.Whispers.Distance = RPTools.Config.WhisperDistance
RPTools.Whispers.errors = {
    tagNotFound = 0;
}

function RPTools.Whispers.formatId(whisper_id)
    return whisper_id
end

function RPTools.Whispers.newWhisper(ent, whisper_id, text, required_tagId, distance, duration, soundUrl)
    if not RPTools.Tags.tagExists(required_tagId) then
        return nil, RPTools.Whispers.errors.tagNotFound
    end

    ent.RPTools = ent.RPTools or {}

    if not ent.RPTools.whispers or ent.RPtools.whispers ~= {} then ent:SetNW2Bool("rptools_has_whispers", true) end

    ent.RPTools.whispers = ent.RPTools.whispers or {}

    ent.RPTools.whispers[RPTools.Whispers.formatId(whisper_id)] = {
        id = RPTools.Whispers.formatId(whisper_id);
        text = text;
        required_tag = required_tagId;

        distance = distance;
        duration = duration;
        soundUrl = soundUrl
    }

    duplicator.StoreEntityModifier(ent, "rptools_whispers", ent.RPTools.whispers)
end


function RPTools.Whispers.copyWhisper(ent, whisper_id, whisper)
    local new_whisper = table.Copy(whisper)

    ent.RPTools = ent.RPTools or {}

    if not ent.RPTools.whispers or ent.RPTools.whispers ~= {} then ent:SetNW2Bool("rptools_has_whispers", true) end

    ent.RPTools.whispers = ent.RPTools.whispers or {}

    new_whisper.id = whisper_id

    ent.RPTools.whispers[RPTools.Whispers.formatId(whisper_id)] = new_whisper

    duplicator.StoreEntityModifier(ent, "rptools_whispers", ent.RPTools.whispers)
end

function RPTools.Whispers.removeWhisper(ent, id)
    ent.RPTools.whispers[RPTools.Whispers.formatId(id)] = nil

    if ent.RPTools.whispers == {} then ent:SetNW2Bool("rptools_has_whispers", false) end

    duplicator.StoreEntityModifier(ent, "rptools_whispers", ent.RPTools.whispers)
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

function RPTools.Whispers.getWhispersForPlayer(ply, tr)
    local valid_whispers_ids = {}
    local ent = tr.Entity
    if not ent.RPTools or not ent.RPTools.whispers then return valid_whispers_ids end

    for whisper_id, whisper_data in pairs(ent.RPTools.whispers) do
        if RPTools.Tags.playerTagged(ply, whisper_data.required_tag) then
            local required_distance = whisper_data.distance
            local actualDistance = ply:EyePos():Distance(tr.HitPos)
            if actualDistance <= required_distance then
                valid_whispers_ids[#valid_whispers_ids+1] = whisper_id
            end
        end
    end

    return valid_whispers_ids

end

function RPTools.Whispers.generateWhisperID()
    return "whisper:" .. os.time() .. "-" .. math.random(1000, 9999)
end

timer.Create("RPTools_WhisperCheck", RPTools.Config.WhisperTickRate, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local dir = ply:EyeAngles():Forward()

        local tr = util.TraceLine({
            start = ply:EyePos();
            endpos = ply:EyePos() + dir * 2000;
            filter = { ply }
        })

        if not tr.Entity or not tr.Entity:IsValid() then continue end

        local whisper_ids = RPTools.Whispers.getWhispersForPlayer(ply, tr)
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
    local tagId = net.ReadString()
    local text = net.ReadString()
    local distance = net.ReadUInt(16)
    local duration = net.ReadUInt(8)
    local soundUrl = net.ReadString()

    RPTools.Whispers.newWhisper(ent, RPTools.Whispers.generateWhisperID(), text, tagId, distance, duration, soundUrl)

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

duplicator.RegisterEntityModifier("rptools_whispers", function(_, ent, data)
    ent.RPTools = ent.RPTools or {}
    ent.RPTools.whispers = data
end)