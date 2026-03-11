
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
        lblTitle:SetText("--- Tag Register ---")
        lblTitle:SetDark(true)
        panel:AddPanel(lblTitle)

        local txtName = vgui.Create("DTextEntry", panel) -- Utilise panel
        txtName:SetPlaceholderText("Tag name...")
        panel:AddPanel(txtName) -- Indispensable pour l'affichage
        
        local mixer = vgui.Create("DColorMixer", panel)
        mixer:SetPalette(true)
        mixer:SetAlphaBar(false)
        panel:AddPanel(mixer)

        local btnAdd = vgui.Create("DButton", panel)
        btnAdd:SetText("Créer le Tag")
        btnAdd.DoClick = function()
            local name = txtName:GetValue()
            if name == "" then return end

            net.Start("rptools_add_tag")
            net.WriteString(name)
            net.WriteColor(mixer:GetColor())
            net.SendToServer()
        end
        panel:AddPanel(btnAdd)

        local tagsList = vgui.Create("DListView", panel)
        tagsList:SetTall(150)
        tagsList:SetMultiSelect(false)
        tagsList:AddColumn("Tags (Right-click to remove)")
        panel:AddPanel(tagsList)

        function RPTools.Tags.RefreshList(list, dataTable)
            list:Clear()
            for id, data in pairs(dataTable) do
                local line = list:AddLine(data.name, " ")
                line.tagID = id

            line.Columns[2].Paint = function(self, w, h)
                draw.RoundedBox(4, 5, 2, w - 10, h - 4, data.colour)
            end

            end
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
            self:Clear()
            for tagID, tagData in pairs(register) do
                local line = self:AddLine(tagData.name, " ")
                line.tagID = tagID
                line.Columns[2].Paint = function(s, w, h)
                    draw.RoundedBox(4, 5, 2, w - 10, h - 4, tagData.colour)
                end
            end
        end)

        local spacer = vgui.Create("DPanel", panel)
        spacer:SetPaintBackground(false)
        spacer:SetTall(20)
        panel:AddPanel(spacer)

        local lblTitlePlayers = vgui.Create("DLabel", panel)
        lblTitlePlayers:SetText("--- Player Tags ---")
        lblTitlePlayers:SetDark(true)
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
            local yOffset = 0
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