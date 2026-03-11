local PANEL = {}

function PANEL:Init()
    self:SetSize(750, 500) 
    self:Center()
    self:MakePopup()

    self.TargetEntity = nil
    self.Whispers = {}
    self.ActiveWhisperID = nil

    self.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, RPTools.Config.Colors.Background())
        
        draw.RoundedBoxEx(6, 0, 0, w, 30, RPTools.Config.Colors.Panel(), true, true, false, false)
        draw.SimpleText("Whisper Editor", "DermaDefaultBold", 10, 15, RPTools.Config.Colors.Text(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    self.btnClose = vgui.Create("DButton", self)
    self.btnClose:SetPos(self:GetWide() - 30, 5)
    self.btnClose:SetSize(20, 20)
    self.btnClose:SetText("X")
    self.btnClose:SetTextColor(RPTools.Config.Colors.Text())
    self.btnClose.Paint = function() end
    self.btnClose.DoClick = function() self:Close() end

    -- On appellera la création des sous-panneaux ici à l'étape suivante !
    self:BuildMasterPanel()
    self:BuildDetailPanel()
end


function PANEL:BuildMasterPanel()
    self.LeftPanel = vgui.Create("DPanel", self)
    self.LeftPanel:Dock(LEFT)
    self.LeftPanel:SetWide(220)
    self.LeftPanel:DockMargin(0, 30, 0, 0)
    
    self.LeftPanel.Paint = function(s, w, h)
        draw.RoundedBoxEx(0, 0, 0, w, h, RPTools.Config.Colors.Panel(), false, false, true, false)
        surface.SetDrawColor(200, 200, 200, 100)
        surface.DrawRect(w - 1, 0, 1, h)
    end

    self.BtnNew = vgui.Create("DButton", self.LeftPanel)
    self.BtnNew:Dock(BOTTOM)
    self.BtnNew:SetTall(40)
    self.BtnNew:DockMargin(10, 10, 10, 10)
    self.BtnNew:SetText("+ NEW WHISPER")
    self.BtnNew:SetTextColor(color_white)
    self.BtnNew.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(50, 50, 55) or RPTools.Config.Colors.Accent()
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    self.BtnNew.DoClick = function()
        if self.SetupNewWhisper then self:SetupNewWhisper() end
    end

    self.ScrollList = vgui.Create("DScrollPanel", self.LeftPanel)
    self.ScrollList:Dock(FILL)
    self.ScrollList:DockMargin(0, 10, 0, 0)
end


function PANEL:RefreshList()
    self.ScrollList:Clear()
    
    if table.IsEmpty(self.Whispers) then return end

    local sortedWhispers = {}
    for id, data in pairs(self.Whispers) do
        local w = table.Copy(data)
        w.id = id
        table.insert(sortedWhispers, w)
    end
    
    table.sort(sortedWhispers, function(a, b)
        return tonumber(a.distance) > tonumber(b.distance)
    end)
    
    for _, data in ipairs(sortedWhispers) do
        local id = data.id
        local tagInfo = self.TagRegister and self.TagRegister[data.required_tag]
        local tagName = tagInfo and tagInfo.name or "Uknown Tag"
        local tagCol = tagInfo and tagInfo.colour or Color(150, 150, 150)
        
        local card = vgui.Create("DButton", self.ScrollList)
        card:Dock(TOP)
        card:SetTall(60)
        card:DockMargin(10, 0, 10, 5)
        card:SetText("")
        
        card.Paint = function(s, w, h)
            local isSelected = (self.ActiveWhisperID == id)
            local bgColor = isSelected and RPTools.Config.Colors.Background() or (s:IsHovered() and RPTools.Config.Colors.Hover() or RPTools.Config.Colors.Panel())
            
            draw.RoundedBox(4, 0, 0, w, h, bgColor)
            draw.RoundedBoxEx(4, 0, 0, 6, h, tagCol, true, false, true, false)
            
            draw.SimpleText(tagName, "DermaDefaultBold", 15, 10, RPTools.Config.Colors.Text(), TEXT_ALIGN_LEFT)
            draw.SimpleText(data.distance .. "u", "DermaDefault", w - 10, 10, RPTools.Config.Colors.TextMuted(), TEXT_ALIGN_RIGHT)
            
            local shortText = string.len(data.text) > 22 and string.Left(data.text, 19) .. "..." or data.text
            draw.SimpleText(shortText, "DermaDefault", 15, 30, RPTools.Config.Colors.TextMuted(), TEXT_ALIGN_LEFT)
        end
        
        card.DoClick = function()
            if self.SelectWhisper then self:SelectWhisper(id, data) end
        end

        card.DoRightClick = function()
            local m = DermaMenu()
            
            local delete = m:AddOption("Delete Whisper", function()
                Derma_Query(
                    "Are you sure you want to delete this whisper?",
                    "Confirmation",
                    "Delete", function()
                        net.Start("rptools_remove_whisper")
                            net.WriteEntity(self.TargetEntity)
                            net.WriteString(id)
                        net.SendToServer()
                        
                        self.Whispers[id] = nil
                        self.ActiveWhisperID = nil
                        self.FormContainer:SetVisible(false)
                        self:RefreshList()
                    end,
                    "Cancel", function() end
                )
            end)
            delete:SetIcon("icon16/delete.png")
            
            m:Open()
        end
    end
end

function PANEL:SetData(activeWhisperID, targetEnt, whispersTable, tagRegister)
    self.TargetEntity = targetEnt
    self.Whispers = whispersTable or {}
    self.TagRegister = tagRegister or {}

    self.TagCombo:Clear()
    if self.TagRegister and not table.IsEmpty(self.TagRegister) then
        for id, data in pairs(self.TagRegister) do 
            self.TagCombo:AddChoice(data.name, id)
        end
    end

    self:SelectWhisper(activeWhisperID, whispersTable[activeWhisperID])

    self:RefreshList()
end


function PANEL:BuildDetailPanel()
    self.RightPanel = vgui.Create("DPanel", self)
    self.RightPanel:Dock(FILL)
    self.RightPanel:DockMargin(25, 45, 25, 20)
    
    self.RightPanel.Paint = function(s, w, h)
        if self.ActiveWhisperID == nil then
            draw.SimpleText("Select a whisper", "DermaLarge", w/2, h/2 - 15, RPTools.Config.Colors.TextMuted(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("or create a new one.", "DermaDefault", w/2, h/2 + 15, RPTools.Config.Colors.TextMuted(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    self.FormContainer = vgui.Create("DPanel", self.RightPanel)
    self.FormContainer:Dock(FILL)
    self.FormContainer.Paint = function() end
    self.FormContainer:SetVisible(false)

    self.IsDirty = false
    local function MarkDirty()
        self.IsDirty = true
        if IsValid(self.BtnSave) then self.BtnSave:SetText("SAVE *") end
    end

    -- SECTION 1 : LE TAG (Avec un titre)
    local lblTag = vgui.Create("DLabel", self.FormContainer)
    lblTag:SetText("WHISPER TAG")
    lblTag:SetFont("DermaDefaultBold")
    lblTag:SetTextColor(RPTools.Config.Colors.TextMuted())
    lblTag:Dock(TOP)
    lblTag:DockMargin(0, 0, 0, 5)

    self.TagCombo = vgui.Create("DComboBox", self.FormContainer)
    self.TagCombo:Dock(TOP)
    self.TagCombo:DockMargin(0, 0, 0, 20) -- Espace après le combo
    self.TagCombo:SetTall(25)
    self.TagCombo:SetValue("Select a Tag...")
    self.TagCombo.OnSelect = MarkDirty

    -- SECTION 2 : LE TEXTE (Taille fixe, plus de FILL)
    local lblText = vgui.Create("DLabel", self.FormContainer)
    lblText:SetText("MESSAGE CONTENT")
    lblText:SetFont("DermaDefaultBold")
    lblText:SetTextColor(RPTools.Config.Colors.TextMuted())
    lblText:Dock(TOP)
    lblText:DockMargin(0, 0, 0, 5)

    self.TextEntry = vgui.Create("DTextEntry", self.FormContainer)
    self.TextEntry:Dock(TOP) -- On utilise TOP
    self.TextEntry:SetTall(120) -- On bloque la hauteur !
    self.TextEntry:DockMargin(0, 0, 0, 20)
    self.TextEntry:SetMultiline(true)
    self.TextEntry.OnChange = MarkDirty

    -- SECTION 3 : LE BOUTON SAVE (Fixé tout en bas)
    self.BtnSave = vgui.Create("DButton", self.FormContainer)
    self.BtnSave:Dock(BOTTOM)
    self.BtnSave:SetTall(40) -- Un peu plus gros
    self.BtnSave:DockMargin(0, 10, 0, 0)
    self.BtnSave:SetText("SAVE")
    self.BtnSave:SetTextColor(color_white)
    self.BtnSave.Paint = function(s, w, h)
        local col = self.IsDirty and RPTools.Config.Colors.Accent() or Color(160, 160, 170)
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    self.BtnSave.DoClick = function()
        if not self.IsDirty and self.ActiveWhisperID ~= "" then return end 
        self:OnSave()
    end

    -- SECTION 4 : LES SLIDERS (Remplissent l'espace restant au milieu)
    self.BottomSettings = vgui.Create("DPanel", self.FormContainer)
    self.BottomSettings:Dock(FILL) -- Prend la place entre le texte et le bouton Save
    self.BottomSettings.Paint = function() end

    self.DistSlider = vgui.Create("DNumSlider", self.BottomSettings)
    self.DistSlider:Dock(TOP)
    self.DistSlider:SetText("Activation distance")
    self.DistSlider:SetDark(true)
    self.DistSlider:SetMinMax(50, 2000)
    self.DistSlider:SetDecimals(0)
    self.DistSlider:DockMargin(0, 0, 0, 5)
    self.DistSlider.OnValueChanged = MarkDirty

    self.DurSlider = vgui.Create("DNumSlider", self.BottomSettings)
    self.DurSlider:Dock(TOP)
    self.DurSlider:SetText("Duration (seconds)")
    self.DurSlider:SetDark(true)
    self.DurSlider:SetMinMax(1, 60)
    self.DurSlider:SetDecimals(0)
    self.DurSlider:DockMargin(0, 0, 0, 15)
    self.DurSlider.OnValueChanged = MarkDirty

    self.AudioRow = vgui.Create("DPanel", self.BottomSettings)
    self.AudioRow:Dock(TOP)
    self.AudioRow:SetTall(30)
    self.AudioRow:DockMargin(0, 0, 0, 0)
    self.AudioRow.Paint = function() end

    self.BtnPlay = vgui.Create("DButton", self.AudioRow)
    self.BtnPlay:Dock(RIGHT)
    self.BtnPlay:SetWide(60)
    self.BtnPlay:SetText("PLAY")
    self.BtnPlay.DoClick = function()
        surface.PlaySound(self.SoundEntry:GetValue())
    end

    self.SoundEntry = vgui.Create("DTextEntry", self.AudioRow)
    self.SoundEntry:Dock(FILL)
    self.SoundEntry:DockMargin(0, 0, 5, 0)
    self.SoundEntry:SetPlaceholderText("Path to sound...")
    self.SoundEntry.OnChange = MarkDirty
end

function PANEL:SelectWhisper(id, data)
    if id == "" then return end
    self.ActiveWhisperID = id
    self.FormContainer:SetVisible(true)
    
    self.TextEntry:SetValue(data.text)
    self.DistSlider:SetValue(data.distance)
    self.DurSlider:SetValue(data.duration)
    self.SoundEntry:SetValue(data.soundUrl)
    
    for k, v in pairs(self.TagCombo.Data) do
        if v == data.required_tag then
            self.TagCombo:ChooseOptionID(k)
            break
        end
    end

    self.IsDirty = false
    self.BtnSave:SetText("SAVE")
end

function PANEL:SetupNewWhisper()
    self.ActiveWhisperID = ""
    self.FormContainer:SetVisible(true)
    
    self.TextEntry:SetValue("")
    self.DistSlider:SetValue(RPTools.Config and RPTools.Config.WhisperDistance or 300)
    self.DurSlider:SetValue(RPTools.Config and RPTools.Config.WhisperDuration or 10)
    self.SoundEntry:SetValue(RPTools.Config and RPTools.Config.WhisperSound or "ambient/wind/wind_snippet1.wav")
    if self.TagCombo.Choices and #self.TagCombo.Choices > 0 then
        self.TagCombo:ChooseOptionID(1)
    else
        self.TagCombo:SetValue("Aucun tag disponible")
    end

    self.IsDirty = true
    self.BtnSave:SetText("SAVE *")
end

function PANEL:OnSave()
    local _, tagID = self.TagCombo:GetSelected() 
    if not tagID then 
        notification.AddLegacy("Please select a tag !", NOTIFY_ERROR, 3)
        return
    end

    if not IsValid(self.TargetEntity) then return end

    net.Start("rptools_add_whisper")
        net.WriteEntity(self.TargetEntity)
        net.WriteString(tagID)
        net.WriteString(self.TextEntry:GetValue())
        net.WriteUInt(self.DistSlider:GetValue(), 16)
        net.WriteUInt(self.DurSlider:GetValue(), 8)
        net.WriteString(self.SoundEntry:GetValue())
        net.WriteString(self.ActiveWhisperID)
    net.SendToServer()
    
    self.IsDirty = false
    self.BtnSave:SetText("✔ SAVED")
    
    timer.Simple(2, function()
        if IsValid(self.BtnSave) and not self.IsDirty then
            self.BtnSave:SetText("SAVE")
        end
    end)
end

vgui.Register("RPTools_WhisperEditor", PANEL, "DFrame")