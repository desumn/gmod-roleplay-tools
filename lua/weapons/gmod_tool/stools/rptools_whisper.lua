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
        f:SetSize(500, 450)
        f:SetTitle("Whisper Editor - " .. target:GetClass())
        f:Center()
        f:MakePopup()
        RPTools.EditorFrame = f

        local addPanel = vgui.Create("DPanel", f)
        addPanel:Dock(TOP)
        addPanel:SetTall(120)
        addPanel:DockMargin(0, 0, 0, 10)

        local combo = vgui.Create("DComboBox", addPanel)
        combo:Dock(TOP)
        combo:DockMargin(5, 5, 5, 5)
        combo:SetValue("Select a Tag...")
        if RPTools.UI.registerList then
            for _, tag in pairs(RPTools.UI.registerList) do combo:AddChoice(tag) end
        end

        local txt = vgui.Create("DTextEntry", addPanel)
        txt:Dock(FILL)
        txt:DockMargin(5, 0, 5, 5)
        txt:SetPlaceholderText("Whisper text")
        txt:SetMultiline(true)

        local btn = vgui.Create("DButton", addPanel)
        btn:Dock(BOTTOM)
        btn:SetText("AJOUTER LE WHISPER")
        btn.DoClick = function()
            net.Start("rptools_add_whisper")
            net.WriteEntity(target)
            net.WriteString(combo:GetValue())
            net.WriteString(txt:GetValue())
            net.SendToServer()
        end

        local list = vgui.Create("DListView", f)
        list:Dock(FILL)
        list:AddColumn("Tag"):SetFixedWidth(100)
        list:AddColumn("Text")

        for id, data in pairs(whispers) do
            local line = list:AddLine(data.required_tag, data.text)
            line.whisperID = id
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



