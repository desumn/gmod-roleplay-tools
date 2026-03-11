
if sam then
    
    sam.command.new("tag")
    :SetPermission("rptools_admin", "admin")
    :AddArg("player")
    :AddArg("text", {hint = "tag_name"})
    :Help("Add a tag to a player.")
    :OnExecute(function(ply, targets, tag_name)
        local tag_id = RPTools.Tags.findTagByName(tag_name)
        
        local args =  {A = ply; V = tag_name; T = targets}

        if not tag_id then
            return sam.player.send_message(ply, "The tag {V} does not exist.", args)
        end
        
        for _, target in ipairs(targets) do
            RPTools.Tags.tagPlayer(target, tag_id)
        end
        
        sam.player.send_message(nil, "{A} added the tag {V} to {T}", args)
    end)
    :End()
    
    sam.command.new("untag")
    :SetPermission("rptools_admin", "admin")
    :AddArg("player")
    :AddArg("text", {hint = "tag_name"})
    :Help("Remove a tag from a player.")
    :OnExecute(function(ply, targets, tag_name)
        local tag_id = RPTools.Tags.findTagByName(tag_name)
        
        local args =  {A = ply; V = tag_name; T = targets}

        if not tag_id then
            return sam.player.send_message(ply, "The tag {V} does not exist.", args)
        end
        
        for _, target in ipairs(targets) do
            RPTools.Tags.untagPlayer(target, tag_id)
        end
        
        sam.player.send_message(nil, "{A} removed the tag {V} from {T}", args)
    end)
    :End()
    
end