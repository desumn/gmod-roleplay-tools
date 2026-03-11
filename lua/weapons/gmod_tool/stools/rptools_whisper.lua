TOOL.Category = "RPTools"
TOOL.Name = "Whispers"


RPTools = RPTools or {}
RPTools.UI = RPTools.UI or {}

if CLIENT then

    TOOL.Information = {
        { name = "left", stage = 0 },
        { name = "right_copy", stage = 0, icon = "gui/rmb.png" },
        
        { name = "left", stage = 1 },
        { name = "right_paste", stage = 1, icon = "gui/rmb.png" },
        { name = "reload", stage = 1 }
    }

    language.Add("tool.rptools_whisper.name", "Whispers")
    language.Add("tool.rptools_whisper.desc", "Manage an entity whispers")
    language.Add("tool.rptools_whisper.left", "Open entity's whisper menu")
    language.Add("tool.rptools_whisper.right_copy", "Copy entity whispers")
    language.Add("tool.rptools_whisper.right_paste", "Paste entity whispers")
    language.Add("tool.rptools_whisper.reload", "Cancel copy")

    RPTools.UI.SelectedEntity = nil
    RPTools.UI.SelectedWhispers = {}
end

if SERVER then

    function TOOL:LeftClick(trace)
        local ent = trace.Entity
        local ply = self:GetOwner()

        if not IsValid(ent) or ent:IsPlayer() or ent:IsWorld() then return false end
        if not RPTools.CanAdmin(ply) then return false end

        if not ent.RPTools then ent.RPTools = {} end

        net.Start("rptools_open_editor")
        net.WriteEntity(ent)
        net.WriteTable(ent.RPTools.whispers or {})
		net.WriteTable(RPTools.Tags.getAllTags() or {})
        net.Send(ply)

        return true
    end

    function TOOL:RightClick(trace)
        local ent = trace.Entity
        local ply = self:GetOwner()

        if not IsValid(ent) or ent:IsPlayer() or ent:IsWorld() then return false end
        if not RPTools.CanAdmin(ply) then return false end

        if self:GetStage() == 0 then
            if not ent.RPTools or not ent.RPTools.whispers or ent.RPTools.whispers == {} then return false end
            if not ply.RPTools then ply.RPTools = {} end
            ply.RPTools.SelectedCopyWhispers = table.Copy(ent.RPTools.whispers)
            self:SetStage(1)
            ply:SendLua([[notification.AddLegacy( "Copied ]] .. table.Count(ply.RPTools.SelectedCopyWhispers) .. [[ whispers.", NOTIFY_GENERIC, 2 )]])
        elseif self:GetStage() == 1 then
            ent.RPTools = ent.RPTools or {}
            ent.RPTools.whispers = ent.RPTools.whispers or {}

            for oldId, whisper in pairs(ply.RPTools.SelectedCopyWhispers) do
                local newId = RPTools.Whispers.generateWhisperID()
                if ent.RPTools.whispers[oldId] then continue end
                RPTools.Whispers.copyWhisper(ent, newId, whisper)
            end
            self:SetStage(0)
            ply:SendLua([[notification.AddLegacy( "Pasted ]] .. table.Count(ply.RPTools.SelectedCopyWhispers) .. [[ whispers.", NOTIFY_GENERIC, 2 )]])
        end

        return true
    end

    function TOOL:Reload(trace)
        local ply = self:GetOwner()

        if not RPTools.CanAdmin(ply) then return false end

        if self:GetStage() == 1 then
            ply.RPTools.SelectedCopyWhispers = {}
            self:SetStage(0)
            ply:SendLua([[notification.AddLegacy( "Cleared Whispers clipboard.", NOTIFY_CLEANUP, 2 )]])
        end

        local ent = trace.Entity
		if IsValid(ent) and ent.RPTools and ent.RPTools.whispers and not table.IsEmpty(ent.RPTools.whispers) then
			local whispers = ent.RPTools.whispers
			local max = table.Count(whispers)
			local weapon = self:GetWeapon()

			local current = weapon:GetNW2Int("RPTools_SelectedIdx", 0) + 1
			if current > max then current = 1 end

			local i = 0
			for _, data in pairs(whispers) do
				i = i + 1
				if i == current then
					weapon:SetNW2Int("RPTools_SelectedIdx", current)
					weapon:SetNW2String("RPTools_SelectedText", data.text)
					weapon:SetNW2String("RPTools_SelectedTag", data.required_tag)
					weapon:SetNW2Int("RPTools_SelectedDist", data.distance)
					break
				end
			end

			ply:SendLua([[surface.PlaySound("buttons/lightswitch2.wav")]])
			return true
		else
			local weapon = self:GetWeapon()
			weapon:SetNW2Int("RPTools_SelectedIdx", 0)
			weapon:SetNW2String("RPTools_SelectedText", 0)
			weapon:SetNW2String("RPTools_SelectedTag", "")
			weapon:SetNW2Int("RPTools_SelectedDist", 0)
			return false
		 end

        return true
    end

end

if CLIENT then
    net.Receive("rptools_open_editor", function(_, _)
       	local target = net.ReadEntity()
    	local whispers = net.ReadTable()
		local tagRegister = net.ReadTable()
		local activeWhisperId = net.ReadString()

		if IsValid(RPTools.EditorFrame) then 
            RPTools.EditorFrame:SetData(activeWhisperId, target, whispers, tagRegister)
            return
        end

		RPTools.EditorFrame = vgui.Create("RPTools_WhisperEditor")
		RPTools.EditorFrame:SetData("", target, whispers, tagRegister)

    end)

	function TOOL:DrawToolScreen(width, height)
		local weapon = self:GetWeapon()
		local idx = weapon:GetNW2Int("RPTools_SelectedIdx", 0)

		surface.SetDrawColor(20, 20, 30)
		surface.DrawRect(0, 0, width, height)

		if idx > 0 then
			local tagID = weapon:GetNW2String("RPTools_SelectedTag", "")
			local text = weapon:GetNW2String("RPTools_SelectedText", "")
			local dist = weapon:GetNW2Int("RPTools_SelectedDist", 0)
			
			local tag = RPTools.UI.registerList[tagID]
			local tagCol = tag and tag.colour or color_white

			draw.SimpleText("WHISPER " .. idx, "RPTools_ToolScreenText", width / 2, 35, color_white, TEXT_ALIGN_CENTER)
			draw.SimpleText(tag and string.upper(tag.name) or "TAG", "RPTools_ToolScreenTag", width / 2, 90, tagCol, TEXT_ALIGN_CENTER)
			
			local displayTxt = (string.len(text) > 35) and (string.Left(text, 32) .. "...") or text
			draw.DrawText(displayTxt, "RPTools_ToolScreenText", width / 2, 135, color_white, TEXT_ALIGN_CENTER)
			
			draw.SimpleText("RANGE : " .. dist .. "u", "RPTools_ToolScreenText", width / 2, height - 35, Color(150, 150, 150), TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("RELOAD TO CYCLE", "RPTools_ToolScreenText", width / 2, height / 2, Color(100, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

end



