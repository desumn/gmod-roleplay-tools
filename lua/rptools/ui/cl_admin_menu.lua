
RPTools.UI = RPTools.UI or {}
RPTools.Tags = RPTools.Tags or {}

RPTools.UI.registerList = RPTools.UI.registerList or {}

net.Receive("rptools_register_list", function (_, ply)
    RPTools.UI.registerList = net.ReadTable()
    hook.Run("RPTools_OnTagsUpdated", RPTools.UI.registerList)
end)

net.Receive("rptools_player_tags", function (_, ply)
    local targetPlayer = net.ReadPlayer()
    local playerTags = net.ReadTable(true)

    hook.Run("RPTools_OnPlayerTagsUpdated", targetPlayer, playerTags)
end)

hook.Add( "AddToolMenuCategories", "RPTools_Category", function()
	spawnmenu.AddToolCategory( "Utilities", "RPTools", "#RPTools" )
end )

surface.CreateFont("RPTools_MenuTitle", {
    font = "Roboto",
    size = 20,
    weight = 800,
})

hook.Add("PopulateToolMenu", "RPTools_AdminMenu", function()
    
    spawnmenu.AddToolMenuOption("Utilities", "RPTools", "RPTools_Tag_Management", "#Tags Management", "", "", function(panel)
        
        panel:ClearControls()

        if not LocalPlayer():IsAdmin() then
            local lblAdmin = vgui.Create("DLabel", panel)
            lblAdmin:SetText("Admin-only menu")
            lblAdmin:SetDark(true)
            panel:AddPanel(lblAdmin)
            return
        end

        local lblTitle = vgui.Create("DLabel", panel)
        lblTitle:SetText("Tag Management")
        lblTitle:SetFont("RPTools_MenuTitle")
        lblTitle:SetDark(true)
        lblTitle:SizeToContents()
        lblTitle:DockMargin(0, 0, 0, 5)
        panel:AddPanel(lblTitle)

        local txtName = vgui.Create("DTextEntry", panel)
        txtName:SetPlaceholderText("Tag name...")
        panel:AddPanel(txtName)
        
        local mixer = vgui.Create("DColorMixer", panel)
        mixer:SetTall(110)
        mixer:SetPalette(false)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)
        panel:AddPanel(mixer)

        local btnAdd = vgui.Create("DButton", panel)
        btnAdd:SetText("Create Tag")
        btnAdd:SetIcon("icon16/tag_blue_add.png")
        btnAdd.DoClick = function()
            local name = txtName:GetValue()
            if name == "" then return end

            net.Start("rptools_add_tag")
            net.WriteString(name)
            net.WriteColor(mixer:GetColor())
            net.SendToServer()
            txtName:SetValue("")
        end
        panel:AddPanel(btnAdd)

        local tagsSearchBar = vgui.Create("DTextEntry", panel)
        tagsSearchBar:SetPlaceholderText("Search for a tag...")
        tagsSearchBar:SetUpdateOnType(true)
        panel:AddPanel(tagsSearchBar)

        local tagsList = vgui.Create("DListView", panel)
        tagsList:SetTall(150)
        tagsList:SetMultiSelect(false)
        tagsList:AddColumn("Tags (Right-click to remove)")
        panel:AddPanel(tagsList)

        local function refreshList(list, dataTable, filter)
            list:Clear()
            filter = filter and string.lower(filter) or ""
            for id, data in pairs(dataTable) do
                if string.find(string.lower(data.name), filter, 1, true) then
                    local line = list:AddLine(data.name, " ")
                    line.tagID = id
                    line.Columns[2].Paint = function(self, w, h)
                    draw.RoundedBox(4, 5, 2, w - 10, h - 4, data.colour)
                end
            end

            end
        end

        tagsSearchBar.OnValueChange = function(self, filter)
            refreshList(tagsList, RPTools.UI.registerList, filter)
        end

       tagsList.OnRowRightClick = function(self, lineID, line)
            local menu = DermaMenu()
            menu:AddOption("Supprimer", function()
                net.Start("rptools_remove_tag")
                net.WriteString(line.tagID) -- Utilise l'ID stocké dans la ligne
                net.SendToServer()
            end):SetIcon("icon16/delete.png")
            menu:Open()
        end

        hook.Add("RPTools_OnTagsUpdated", tagsList, function(self, register)
            if not IsValid(self) then return end
            refreshList(self, register, tagsSearchBar:GetValue())
        end)

        local spacer = vgui.Create("DPanel", panel)
        spacer:SetTall(15)
        spacer.Paint = function(self, w, h)
            draw.RoundedBox(0, 10, h/2, w-20, 1, Color(0, 0, 0, 50)) 
        end
        panel:AddPanel(spacer)


        local lblTitlePlayers = vgui.Create("DLabel", panel)
        lblTitlePlayers:SetText("Player Tags Management")
        lblTitlePlayers:SetFont("RPTools_MenuTitle")
        lblTitlePlayers:SetDark(true)
        lblTitlePlayers:SizeToContents()
        lblTitlePlayers:DockMargin(0, 0, 0, 5)
        panel:AddPanel(lblTitlePlayers)

        local searchBar = vgui.Create("DTextEntry", panel)
        searchBar:SetPlaceholderText("Search for a player...")
        searchBar:SetUpdateOnType(true)
        panel:AddPanel(searchBar)

        local plyList = vgui.Create("DListView", panel)
        plyList:SetTall(150)
        plyList:SetMultiSelect(false)
        plyList:AddColumn("Connected players")
        panel:AddPanel(plyList)

        local function RefreshPlayerList(filter)
            plyList:Clear()
            filter = filter and string.lower(filter) or ""
            for _, ply in ipairs(player.GetAll()) do
                if string.find(string.lower(ply:Nick()), filter, 1, true) then
                    local line = plyList:AddLine(ply:Nick())
                    line.playerEnt = ply
                end
            end
        end

        RefreshPlayerList()

        searchBar.OnValueChange = function(self, value)
            RefreshPlayerList(value)
        end

        plyList.OnRowSelected = function(self, rowIndex, row)
            local selectedPlayer = row.playerEnt
            
            if IsValid(selectedPlayer) then
                net.Start("rptools_player_tags")
                net.WriteEntity(selectedPlayer)
                net.SendToServer()
            end
        end

        plyList.OnRowRightClick = function(self, rowIndex, row)
            local selectedPlayer = row.playerEnt
            if not IsValid(selectedPlayer) then return end

            local menu = DermaMenu()
            menu:AddOption("Clear tags", function()
                Derma_Query(
                    "Are you sure you want to clear " .. selectedPlayer:Nick() .. "'s tags ?",
                    "Clear player tags",
                    "Yes", function()
                        net.Start("rptools_clear_player_tags")
                        net.WriteEntity(selectedPlayer)
                        net.SendToServer()
                    end,
                    "Nah", function() end
                )
            end):SetIcon("icon16/tag_blue_delete.png")
            menu:Open()
        end

        local btnClearAll = vgui.Create("DButton", panel)
        btnClearAll:SetText("CLEAR ALL PLAYER TAGS")
        btnClearAll:SetTextColor(Color(255, 50, 50))
        btnClearAll.DoClick = function()
            Derma_Query(
                "Are you sure you want to REMOVE ALL TAGS from ALL PLAYERS? This action is irreversible.",
                "Confirm clean-up",
                "Yes, clear everything.", function()
                    net.Start("rptools_nuke_player_tags")
                    net.SendToServer()
                end,
                "Actually, no", function() end
            )
        end
        panel:AddPanel(btnClearAll)

        local checkboxContainer = vgui.Create("DPanel", panel)
        checkboxContainer:SetPaintBackground(false)
        panel:AddPanel(checkboxContainer)

        hook.Add("RPTools_OnPlayerTagsUpdated", checkboxContainer, function(self, targetPly, plyOwnedIDs)
            if not IsValid(self) then return end
            self:Clear()

            local lblTarget = vgui.Create("DLabel", self)
            lblTarget:SetPos(10, 5)
            lblTarget:SetText(targetPly:Nick() .. "'s tags: ")
            lblTarget:SetFont("DermaDefaultBold")
            lblTarget:SetDark(true)
            lblTarget:SizeToContents()
            
            local yOffset = 25
            for id, data in pairs(RPTools.UI.registerList) do     
                local chk = vgui.Create("DCheckBoxLabel", self)
                chk:SetPos(10, yOffset)
                chk:SetText(data.name)
                chk:SetTextColor(data.colour)
                chk:SetDark(true)
                chk:SizeToContents()

                local hasTag = false
                for _, ownedID in pairs(plyOwnedIDs) do
                    if ownedID == id then hasTag = true break end
                end
                
                chk:SetValue(hasTag)

                chk.OnChange = function(s, state)
                    if state then
                        net.Start("rptools_tag_player")
                    else
                        net.Start("rptools_untag_player")
                    end
                        net.WriteString(id)
                        net.WriteEntity(targetPly)
                    net.SendToServer()
                end

                yOffset = yOffset + 25
            end
            
            self:SetTall(yOffset)

            
        end)

        net.Start("rptools_register_list")
        net.SendToServer()

    end)
end)

hook.Add("SpawnMenuOpen", "RPTools_SyncAdminMenu", function()
    if LocalPlayer():IsAdmin() then
        net.Start("rptools_register_list")
        net.SendToServer()
    end
end)