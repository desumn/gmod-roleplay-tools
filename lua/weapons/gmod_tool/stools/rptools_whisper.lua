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
        if not ply:IsAdmin() then return false end

        if not ent.RPTools then ent.RPTools = {} end

        net.Start("rptools_open_editor")
        net.WriteEntity(ent)
        net.WriteTable(ent.RPTools.whispers or {})
        net.Send(ply)

        return true
    end

    function TOOL:RightClick(trace)
        local ent = trace.Entity
        local ply = self:GetOwner()

        if not IsValid(ent) or ent:IsPlayer() or ent:IsWorld() then return false end
        if not ply:IsAdmin() then return false end

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

        if not ply:IsAdmin() then return false end

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

        if IsValid(RPTools.EditorFrame) then RPTools.EditorFrame:Close() end

        local f = vgui.Create("DFrame")
        f:SetSize(500, 600)
        f:SetTitle("Whisper Editor - " .. target:GetClass())
        f:Center()
        f:MakePopup()
        RPTools.EditorFrame = f

        local addPanel = vgui.Create("DPanel", f)
        addPanel:Dock(TOP)
        addPanel:SetTall(250)
        addPanel:DockMargin(0, 0, 0, 10)

        local combo = vgui.Create("DComboBox", addPanel)
        combo:Dock(TOP)
        combo:DockMargin(5, 5, 5, 5)
        combo:SetValue("Select a Tag...")
        if RPTools.UI.registerList then
            for id, data in pairs(RPTools.UI.registerList) do 
                combo:AddChoice(data.name, id) 
            end
        end

        local sliderDist = vgui.Create("DNumSlider", addPanel)
        sliderDist:Dock(TOP)
        sliderDist:DockMargin(5, 0, 5, 0)
        sliderDist:SetText("Activation distance")
        sliderDist:SetDark(true)
        sliderDist:SetMinMax(50, 2000)
        sliderDist:SetDecimals(0)
        sliderDist:SetValue(RPTools.Config and RPTools.Config.WhisperDistance or 300)

        local sliderDur = vgui.Create("DNumSlider", addPanel)
        sliderDur:Dock(TOP)
        sliderDur:DockMargin(5, 0, 5, 0)
        sliderDur:SetText("Duration of whisper (in second)")
        sliderDur:SetDark(true)
        sliderDur:SetMinMax(1, 60)
        sliderDur:SetDecimals(0)
        sliderDur:SetValue(RPTools.Config and RPTools.Config.WhisperDuration or 10)

        local txtSound = vgui.Create("DTextEntry", addPanel)
        txtSound:Dock(TOP)
        txtSound:DockMargin(5, 5, 5, 5)
        txtSound:SetPlaceholderText("Path to sound played when discovering whisper...")
        txtSound:SetValue(RPTools.Config and RPTools.Config.WhisperSound or "ambient/wind/wind_snippet1.wav")

        local txt = vgui.Create("DTextEntry", addPanel)
        txt:Dock(FILL)
        txt:DockMargin(5, 0, 5, 5)
        txt:SetPlaceholderText("Whisper text")
        txt:SetMultiline(true)

        local btn = vgui.Create("DButton", addPanel)
        btn:Dock(BOTTOM)
        btn:SetText("ADD WHISPER")
        btn.DoClick = function()
            local _, tagID = combo:GetSelected() 
    
            if not tagID then 
                notification.AddLegacy("Please select a tag!", NOTIFY_ERROR, 3)
                return 
            end

            net.Start("rptools_add_whisper")
            net.WriteEntity(target)
            net.WriteString(tagID)
            net.WriteString(txt:GetValue())

            net.WriteUInt(sliderDist:GetValue(), 16)
            net.WriteUInt(sliderDur:GetValue(), 8)
            net.WriteString(txtSound:GetValue())

            net.SendToServer()
        end

        local list = vgui.Create("DListView", f)
        list:Dock(FILL)
        list:AddColumn("Tag"):SetFixedWidth(100)
        list:AddColumn("Text")

        for id, data in pairs(whispers) do
            local tagInfo = RPTools.UI.registerList[data.required_tag]
            local displayName = tagInfo and tagInfo.name or "Tag Inconnu (" .. data.required_tag .. ")"
    
            local line = list:AddLine(displayName, data.text)
            line.whisperID = id
    
            if tagInfo then
                line.Columns[1]:SetTextColor(tagInfo.colour)
            end
        end

        list.OnRowRightClick = function(p, id, line)
            local m = DermaMenu()
            m:AddOption("Remove", function()
                net.Start("rptools_remove_whisper")
                net.WriteEntity(target)
                net.WriteString(line.whisperID)
                net.SendToServer()
            end):SetIcon("icon16/delete.png")
            m:Open()
        end
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



