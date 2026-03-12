
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

    ent.RPTools.whispers = ent.RPTools.whispers or {}

    ent.RPTools.whispers[RPTools.Whispers.formatId(whisper_id)] = {
        id = RPTools.Whispers.formatId(whisper_id);
        text = text;
        required_tag = required_tagId;

        distance = distance;
        duration = duration;
        soundUrl = soundUrl
    }

    ent:SetNW2Bool("rptools_has_whispers", true)

    net.Start("rptools_invalidate_whispers_cache")
    net.WriteUInt(ent:EntIndex(), 16)
    net.Broadcast()

    duplicator.StoreEntityModifier(ent, "rptools_whispers", ent.RPTools.whispers)
end


function RPTools.Whispers.copyWhisper(ent, whisper_id, whisper)
    local new_whisper = table.Copy(whisper)

    ent.RPTools = ent.RPTools or {}

    ent.RPTools.whispers = ent.RPTools.whispers or {}

    new_whisper.id = whisper_id

    ent.RPTools.whispers[RPTools.Whispers.formatId(whisper_id)] = new_whisper
    ent:SetNW2Bool("rptools_has_whispers", true)

    duplicator.StoreEntityModifier(ent, "rptools_whispers", ent.RPTools.whispers)
end

function RPTools.Whispers.removeWhisper(ent, id)
    ent.RPTools.whispers[RPTools.Whispers.formatId(id)] = nil

    if table.IsEmpty(ent.RPTools.whispers) then ent:SetNW2Bool("rptools_has_whispers", false) end

    net.Start("rptools_invalidate_whispers_cache")
    net.WriteUInt(ent:EntIndex(), 16)
    net.Broadcast()


    duplicator.StoreEntityModifier(ent, "rptools_whispers", ent.RPTools.whispers)
end

function RPTools.Whispers.generateWhisperID()
    return "whisper:" .. os.time() .. "-" .. math.random(1000, 9999)
end

function RPTools.Whispers.listAuthorizedWhispers(ply, ent)

    local whispers = {}
    for _, whisper in pairs(ent.RPTools.whispers) do
        if RPTools.Tags.playerTagged(ply, whisper.required_tag) then
            table.insert(whispers, whisper)
        end
    end
    return whispers
end

duplicator.RegisterEntityModifier("rptools_whispers", function(_, ent, data)
    ent.RPTools = ent.RPTools or {}
    ent.RPTools.whispers = data
    if not table.IsEmpty(data) then ent:SetNW2Bool("rptools_has_whispers", true) end
end)


net.Receive("rptools_add_whisper", function(len, ply)
    if not RPTools.CanAdmin(ply) then return end
    
    local ent = net.ReadEntity()
    local tagId = net.ReadString()
    local text = net.ReadString()
    local distance = net.ReadUInt(16)
    local duration = net.ReadUInt(8)
    local soundUrl = net.ReadString()
    local tempWhisperId = net.ReadString()

    if not IsValid(ent) then return end

    local whisperId = tempWhisperId
    if whisperId == "" or not (ent.RPTools and ent.RPTools.whispers and ent.RPTools.whispers[whisperId]) then
        whisperId = RPTools.Whispers.generateWhisperID()
    end

    RPTools.Whispers.newWhisper(ent, whisperId, text, tagId, distance, duration, soundUrl)

    net.Start("rptools_open_editor")
    net.WriteEntity(ent)
    net.WriteTable(ent.RPTools.whispers or {})
    net.WriteTable(RPTools.Tags.getAllTags())
    net.WriteString(whisperId)
    net.Send(ply)
end)

net.Receive("rptools_remove_whisper", function(len, ply)
    if not RPTools.CanAdmin(ply) then return end
    
    local ent = net.ReadEntity()
    local id = net.ReadString()
    
    RPTools.Whispers.removeWhisper(ent, id)
    
    net.Start("rptools_open_editor")
    net.WriteEntity(ent)
    net.WriteTable(ent.RPTools.whispers or {})
    net.WriteTable(RPTools.Tags.getAllTags())
    net.WriteString(id)
    net.Send(ply)
end)

duplicator.RegisterEntityModifier("rptools_whispers", function(_, ent, data)
    ent.RPTools = ent.RPTools or {}
    ent.RPTools.whispers = data
    if not table.IsEmpty(data) then ent:SetNW2Bool("rptools_has_whispers", true) end
end)


net.Receive("rptools_request_whispers", function(_, ply)
    local entids = net.ReadTable(true)
    local valid_whispers = {}
    local whisper_counts = {}

    for _, entid in ipairs(entids) do
        local entity = Entity(entid)
        if not entity:IsValid() then continue end

        whisper_counts[entid] = 0
        if not entity.RPTools or not entity.RPTools.whispers then continue end

        local authorized_whispers = RPTools.Whispers.listAuthorizedWhispers(ply, entity)
        valid_whispers[entid] = authorized_whispers
        whisper_counts[entid] = #authorized_whispers
    end

    local ent_count = table.Count(whisper_counts)

    net.Start("rptools_request_whispers")
    net.WriteUInt(ent_count, 8)

    for entid, whisper_count in pairs(whisper_counts) do
        net.WriteUInt(entid, 16)
        net.WriteUInt(whisper_count, 8)

        if whisper_count == 0 then continue end
        for _, whisper in pairs(valid_whispers[entid]) do
            net.WriteString(whisper.id)
            net.WriteString(whisper.text)
            net.WriteString(whisper.required_tag)

            net.WriteUInt(whisper.distance, 12)
            net.WriteUInt(whisper.duration, 8)
            net.WriteString(whisper.soundUrl)
        end
    end
    net.Send(ply)
end)

hook.Add("EntityRemoved", "rptools_invalidate_cache", function (ent, fullUpdate)
    
    if not ent.RPTools or not ent.RPTools.whispers or table.IsEmpty(ent.RPTools.whispers) then return end

    net.Start("rptools_invalidate_whispers_cache")
    net.WriteUInt(ent:EntIndex(), 16)
    net.Broadcast()
end)