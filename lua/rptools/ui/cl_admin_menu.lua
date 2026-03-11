
RPTools.UI = RPTools.UI or {}
RPTools.Tags = RPTools.Tags or {}

local registerList = {}
local playersTags = {}

net.Receive("rptools_register_list", function (_, ply)
    registerList = net.ReadTable()
    hook.Run("RPTools_OnTagsUpdated", registerList)
end)

net.Receive("rptools_player_tags", function (_, ply)
    local targetPlayer = net.ReadPlayer()
    local playerTags = net.ReadTable(true)

    if not targetPlayer:IsValid() then return end

    playersTags[targetPlayer:SteamID64()] = playerTags

    hook.Run("RPTools_OnPlayerTagsUpdated", targetPlayer, playerTags)
end)

local function OpenCrossReferenceMenu()
    if IsValid(RPTools.AdminDashboard) then RPTools.AdminDashboard:Remove() end

    net.Start("rptools_register_list") 
    net.SendToServer()
    
    for _, p in ipairs(player.GetAll()) do
        net.Start("rptools_player_tags") 
        net.WriteEntity(p) 
        net.SendToServer()
    end

    local FRAME = vgui.Create("DFrame")
    RPTools.AdminDashboard = FRAME
    FRAME:SetSize(900, 600)
    FRAME:Center()
    FRAME:MakePopup()
    FRAME:SetTitle("")
    
    FRAME.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, RPTools.Config.Colors.Background())
        draw.RoundedBoxEx(6, 0, 0, w, 40, RPTools.Config.Colors.Panel(), true, true, false, false)
        draw.SimpleText("RPTools — Tag Management Dashboard", "DermaLarge", 15, 20, RPTools.Config.Colors.Text(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(200, 200, 200, 100)
        surface.DrawRect(w/2, 40, 1, h - 40)
    end

    local btnClose = vgui.Create("DButton", FRAME)
    btnClose:SetSize(30, 30)
    btnClose:SetPos(FRAME:GetWide() - 35, 5)
    btnClose:SetText("✕")
    btnClose:SetFont("DermaDefaultBold")
    btnClose:SetTextColor(RPTools.Config.Colors.Text())
    btnClose.Paint = nil
    btnClose.DoClick = function() FRAME:Close() end

    FRAME.SelectionMode = "NONE"
    FRAME.ActivePlayer = nil
    FRAME.ActiveTagID = nil

    local pnlTags = vgui.Create("DPanel", FRAME)
    pnlTags:Dock(LEFT)
    pnlTags:SetWide(430)
    pnlTags:DockMargin(15, 15, 15, 15)
    pnlTags.Paint = nil

    local lblTags = vgui.Create("DLabel", pnlTags)
    lblTags:Dock(TOP)
    lblTags:SetText("TAGS REGISTER")
    lblTags:SetFont("DermaDefaultBold")
    lblTags:SetTextColor(RPTools.Config.Colors.TextMuted())
    lblTags:DockMargin(0, 0, 0, 10)

    FRAME.SearchTags = vgui.Create("DTextEntry", pnlTags)
    FRAME.SearchTags:Dock(TOP)
    FRAME.SearchTags:SetTall(30)
    FRAME.SearchTags:DockMargin(0, 0, 0, 10)
    FRAME.SearchTags:SetPlaceholderText("Search tag...")

    FRAME.ListTags = vgui.Create("DScrollPanel", pnlTags)
    FRAME.ListTags:Dock(FILL)
    FRAME.ListTags:DockMargin(0, 0, 0, 15)

    local btnNewTag = vgui.Create("DButton", pnlTags)
    btnNewTag:Dock(BOTTOM)
    btnNewTag:SetTall(40)
    btnNewTag:SetText("+ CREATE NEW TAG")
    btnNewTag:SetTextColor(color_white)
    btnNewTag.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(50, 50, 55) or RPTools.Config.Colors.Accent()
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    btnNewTag.DoClick = function()
        local popup = vgui.Create("DFrame")
        popup:SetSize(350, 260)
        popup:Center()
        popup:SetTitle("")
        popup:MakePopup()
        popup:DoModal()
        
        popup.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, RPTools.Config.Colors.Background())
            draw.RoundedBoxEx(6, 0, 0, w, 30, RPTools.Config.Colors.Panel(), true, true, false, false)
            draw.SimpleText("Create a New Tag", "DermaDefaultBold", 10, 15, RPTools.Config.Colors.Text(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local btnClosePopup = vgui.Create("DButton", popup)
        btnClosePopup:SetSize(30, 30)
        btnClosePopup:SetPos(popup:GetWide() - 30, 0)
        btnClosePopup:SetText("✕")
        btnClosePopup:SetTextColor(RPTools.Config.Colors.Text())
        btnClosePopup.Paint = nil
        btnClosePopup.DoClick = function() popup:Close() end

        local formContainer = vgui.Create("DPanel", popup)
        formContainer:Dock(FILL)
        formContainer:DockMargin(15, 10, 15, 15)
        formContainer.Paint = nil

        local entryName = vgui.Create("DTextEntry", formContainer)
        entryName:Dock(TOP)
        entryName:SetTall(30)
        entryName:DockMargin(0, 0, 0, 10)
        entryName:SetPlaceholderText("Tag Name...")

        local colorMixer = vgui.Create("DColorMixer", formContainer)
        colorMixer:Dock(FILL)
        colorMixer:DockMargin(0, 0, 0, 15)
        colorMixer:SetPalette(false)
        colorMixer:SetAlphaBar(false)
        colorMixer:SetWangs(true)

        local btnSave = vgui.Create("DButton", formContainer)
        btnSave:Dock(BOTTOM)
        btnSave:SetTall(35)
        btnSave:SetText("SAVE NEW TAG")
        btnSave:SetTextColor(color_white)
        btnSave.Paint = function(s, w, h)
            local col = s:IsHovered() and Color(50, 50, 55) or RPTools.Config.Colors.Accent()
            draw.RoundedBox(4, 0, 0, w, h, col)
        end
        btnSave.DoClick = function()
            local name = entryName:GetValue()
            if string.Trim(name) == "" then return end

            net.Start("rptools_add_tag")
            net.WriteString(name)
            net.WriteColor(colorMixer:GetColor())
            net.SendToServer()
            
            popup:Close()
        end
    end

    local pnlPlayers = vgui.Create("DPanel", FRAME)
    pnlPlayers:Dock(FILL) -- Prend tout le reste de la place à droite
    pnlPlayers:DockMargin(15, 15, 15, 15)
    pnlPlayers.Paint = nil

    local lblPlayers = vgui.Create("DLabel", pnlPlayers)
    lblPlayers:Dock(TOP)
    lblPlayers:SetText("CONNECTED PLAYERS")
    lblPlayers:SetFont("DermaDefaultBold")
    lblPlayers:SetTextColor(RPTools.Config.Colors.TextMuted())
    lblPlayers:DockMargin(0, 0, 0, 10)

    FRAME.SearchPlayers = vgui.Create("DTextEntry", pnlPlayers)
    FRAME.SearchPlayers:Dock(TOP)
    FRAME.SearchPlayers:SetTall(30)
    FRAME.SearchPlayers:DockMargin(0, 0, 0, 10)
    FRAME.SearchPlayers:SetPlaceholderText("Search player...")

    FRAME.ListPlayers = vgui.Create("DScrollPanel", pnlPlayers)
    FRAME.ListPlayers:Dock(FILL)

    FRAME.RefreshUI = function(self)
        self.ListTags:Clear()
        self.ListPlayers:Clear()
        
        local filterT = string.lower(self.SearchTags:GetValue())
        local filterP = string.lower(self.SearchPlayers:GetValue())

        for id, data in pairs(registerList) do
            if string.find(string.lower(data.name), filterT, 1, true) then
                local card = self.ListTags:Add("DButton")
                card:Dock(TOP)
                card:SetTall(45)
                card:DockMargin(0, 0, 10, 5)
                card:SetText("")
                
                card.Paint = function(s, w, h)
                    local isHovered = s:IsHovered()
                    local isActive = (self.SelectionMode == "TAG" and self.ActiveTagID == id)
                    
                    local playerHasTag = false
                    if self.SelectionMode == "PLAYER" and IsValid(self.ActivePlayer) then
                        local cache = playersTags[self.ActivePlayer:SteamID64()] or {}
                        playerHasTag = table.HasValue(cache, id)
                    end

                    local bgColor = RPTools.Config.Colors.Panel()
                    if isActive then bgColor = RPTools.Config.Colors.Background() 
                    elseif isHovered then bgColor = RPTools.Config.Colors.Hover() end

                    draw.RoundedBox(4, 0, 0, w, h, bgColor)
                    
                    local colAlpha = (self.SelectionMode == "PLAYER" and not playerHasTag) and 80 or 255
                    local finalCol = ColorAlpha(data.colour, colAlpha)
                    draw.RoundedBoxEx(4, 0, 0, 8, h, finalCol, true, false, true, false)
                    
                    local txtCol = (self.SelectionMode == "PLAYER" and not playerHasTag) and RPTools.Config.Colors.TextMuted() or RPTools.Config.Colors.Text()
                    draw.SimpleText(data.name, "DermaDefaultBold", 20, h/2, txtCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                    if self.SelectionMode == "PLAYER" and playerHasTag then
                        surface.SetDrawColor(255, 255, 255, 255)
                        surface.SetMaterial(Material("icon16/tick.png"))
                        surface.DrawTexturedRect(w - 25, h/2 - 8, 16, 16)
                    end
                end

                card.DoClick = function()
                    if self.SelectionMode == "PLAYER" and IsValid(self.ActivePlayer) then
                        local cache = playersTags[self.ActivePlayer:SteamID64()] or {}
                        if table.HasValue(cache, id) then net.Start("rptools_untag_player") else net.Start("rptools_tag_player") end
                        net.WriteString(id)
                        net.WriteEntity(self.ActivePlayer)
                        net.SendToServer()
                    elseif self.SelectionMode == "TAG" and self.ActiveTagID == id then
                        self.SelectionMode = "NONE"
                        self.ActiveTagID = nil
                        self:RefreshUI()
                    else
                        self.SelectionMode = "TAG"
                        self.ActiveTagID = id
                        self.ActivePlayer = nil
                        self:RefreshUI()
                    end
                end

                card.DoRightClick = function()
                    local menu = DermaMenu()
                    menu:AddOption("Delete Tag", function()
                        net.Start("rptools_remove_tag")
                        net.WriteString(id)
                        net.SendToServer()
                        
                        if self.ActiveTagID == id then
                            self.SelectionMode = "NONE"
                            self.ActiveTagID = nil
                            self:RefreshUI()
                        end
                    end):SetIcon("icon16/delete.png")
                    menu:Open()
                end

            end
        end

        for _, ply in ipairs(player.GetAll()) do
            if string.find(string.lower(ply:Nick()), filterP, 1, true) then
                local card = self.ListPlayers:Add("DButton")
                card:Dock(TOP)
                card:SetTall(45)
                card:DockMargin(0, 0, 10, 5)
                card:SetText("")
                
                card.Paint = function(s, w, h)
                    local isHovered = s:IsHovered()
                    local isActive = (self.SelectionMode == "PLAYER" and self.ActivePlayer == ply)
                    
                    local hasActiveTag = false
                    if self.SelectionMode == "TAG" and self.ActiveTagID then
                        local cache = playersTags[ply:SteamID64()] or {}
                        hasActiveTag = table.HasValue(cache, self.ActiveTagID)
                    end

                    local bgColor = RPTools.Config.Colors.Panel()
                    if isActive then bgColor = RPTools.Config.Colors.Background() 
                    elseif isHovered then bgColor = RPTools.Config.Colors.Hover() end

                    draw.RoundedBox(4, 0, 0, w, h, bgColor)

                    local stripeColor = RPTools.Config.Colors.TextMuted(50)
                    local textOffsetX = 20

                    if self.SelectionMode == "TAG" and self.ActiveTagID then
                        local tagData = registerList[self.ActiveTagID]
                        if tagData then
                            local colAlpha = hasActiveTag and 255 or 50
                            stripeColor = ColorAlpha(tagData.colour, colAlpha)
                        end
                    end
                    
                    draw.RoundedBoxEx(4, 0, 0, 8, h, stripeColor, true, false, true, false)

                    local txtCol = RPTools.Config.Colors.Text()
                    if self.SelectionMode == "TAG" and not hasActiveTag then txtCol = RPTools.Config.Colors.TextMuted() end

                    draw.SimpleText(ply:Nick(), "DermaDefaultBold", textOffsetX, h/2, txtCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                    if self.SelectionMode == "TAG" and hasActiveTag then
                        surface.SetDrawColor(255, 255, 255, 255)
                        surface.SetMaterial(Material("icon16/tick.png"))
                        surface.DrawTexturedRect(w - 25, h/2 - 8, 16, 16)
                    end
                end

                card.DoClick = function()
                    if self.SelectionMode == "TAG" and self.ActiveTagID then
                        local cache = playersTags[ply:SteamID64()] or {}
                        if table.HasValue(cache, self.ActiveTagID) then net.Start("rptools_untag_player") else net.Start("rptools_tag_player") end
                        net.WriteString(self.ActiveTagID)
                        net.WriteEntity(ply)
                        net.SendToServer()
                    elseif self.SelectionMode == "PLAYER" and self.ActivePlayer == ply then
                        self.SelectionMode = "NONE"
                        self.ActivePlayer = nil
                        self:RefreshUI()
                    else
                        self.SelectionMode = "PLAYER"
                        self.ActivePlayer = ply
                        self.ActiveTagID = nil
                        self:RefreshUI()
                    end
                end
            end
        end
    end


    FRAME.SearchTags.OnValueChange = function() FRAME:RefreshUI() end
    FRAME.SearchPlayers.OnValueChange = function() FRAME:RefreshUI() end

    FRAME:RefreshUI()

end

concommand.Add("rptools_menu", function(ply)
    if RPTools.CanAdmin(ply) then OpenCrossReferenceMenu() end
end)

hook.Add("OnPlayerChat", "RPTools_ChatCommand", function(ply, text)
    if ply == LocalPlayer() and string.lower(text) == "!rptools" then
        if RPTools.CanAdmin(ply) then
            OpenCrossReferenceMenu()
        end
        return true
    end
end)

hook.Add("RPTools_OnTagsUpdated", "RPTools_RefreshDashTags", function()
    if IsValid(RPTools.AdminDashboard) then RPTools.AdminDashboard:RefreshUI() end
end)

hook.Add("RPTools_OnPlayerTagsUpdated", "RPTools_RefreshDashPlayers", function()
    if IsValid(RPTools.AdminDashboard) then RPTools.AdminDashboard:RefreshUI() end
end)