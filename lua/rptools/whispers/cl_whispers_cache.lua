

RPTools = RPTools or {}
RPTools.Whispers = RPTools.Whispers or {}

RPTools.Whispers.Cache = {}
RPTools.Whispers.Pending = {}

function RPTools.Whispers.askForServerInfo(ent)
    RPTools.Whispers.Pending[ent:EntIndex()] = true
end

function RPTools.Whispers.clearFromCache(ent, entid)
    RPTools.Whispers.Cache[ent and ent:EntIndex() or entid] = nil
end

function RPTools.Whispers.clearPending()
    RPTools.Whispers.Pending = {}
end

function RPTools.Whispers.invalidateCache(entid)
    if entid == 0 then
        RPTools.Whispers.Cache = {}
        for _, ent in ipairs(ents.GetAll()) do
            if ent:GetNW2Bool("rptools_has_whispers", false) then
                RPTools.Whispers.askForServerInfo(ent)
            end
        end
    else
        RPTools.Whispers.clearFromCache(nil, entid)
        local entity = Entity(entid)
        if entity:IsValid() and entity:GetNW2Bool("rptools_has_whispers", false) then
            RPTools.Whispers.askForServerInfo(entity)
        end
    end
end

hook.Add("NetworkEntityCreated", "rptools_entity_scanning", function(ent)
    if not ent:IsValid() then return end
    if not ent:GetNW2Bool("rptools_has_whispers", false) then return end
    
    RPTools.Whispers.askForServerInfo(ent)
    
end)

hook.Add("EntityNetworkedVarChanged", "rptools_entity_modified", function (ent, name, oldval, newval)
    if name ~= "rptools_has_whispers" then return end
    
    if newval then
        RPTools.Whispers.askForServerInfo(ent)
    else
        RPTools.Whispers.clearFromCache(ent, nil)
    end
end)

timer.Create("rptools_batch_send", RPTools.Config.BatchSendDelay, 0, function ()
    if table.IsEmpty(RPTools.Whispers.Pending) then return end
    
    local batch = table.GetKeys(RPTools.Whispers.Pending)
    
    net.Start("rptools_request_whispers")
    net.WriteTable(batch, true)
    net.SendToServer()
    
    RPTools.Whispers.clearPending()
end)

net.Receive("rptools_request_whispers", function (_, _)
    local entcount = net.ReadUInt(8)
    
    for _ = 1, entcount do
        local index = net.ReadUInt(16)
        local whisper_count = net.ReadUInt(8)
        RPTools.Whispers.Cache[index] = {}
        
        for _ = 1, whisper_count do
            local data = {}
            data.id = net.ReadString()
            data.text = net.ReadString()
            data.required_tag = net.ReadString()
            data.distance = net.ReadUInt(12)
            data.duration = net.ReadUInt(8)
            data.soundUrl = net.ReadString()
            
            table.insert(RPTools.Whispers.Cache[index], data)
        end
    end
end)

net.Receive("rptools_invalidate_whispers_cache", function (_, _)
    local entid = net.ReadUInt(16)
    RPTools.Whispers.invalidateCache(entid)
end)

