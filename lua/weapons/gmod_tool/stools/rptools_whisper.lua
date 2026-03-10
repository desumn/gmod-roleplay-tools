TOOL.Category = "RPTools"
TOOL.Name = "Whispers"


RPTools = RPTools or {}
RPTools.UI = RPTools.UI or {}

if CLIENT then
    language.Add("tool.rptools_whisper.name", "Whispers")
    language.Add("tool.rptools_whisper.desc", "Select an entity to manage its whispers")
    language.Add("tool.rptools_whisper.0", "Left Click: Select Entity")

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
        btn:SetText("AJOUTER LE WHISPER")
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

end



