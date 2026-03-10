
RPTools.UI = RPTools.UI or {}

RPTools.UI.registerList = RPTools.UI.registerList or {}

net.Receive("rptools_register_list", function (_, ply)
    RPTools.UI.registerList = net.ReadTable(true)
    hook.Run("RPTools_OnTagsUpdated", RPTools.UI.registerList)
end)

net.Receive("rptools_player_tags", function (_, ply)
    local targetPlayer = net.ReadPlayer()
    local playerTags = net.ReadTable(true)
    PrintTable(playerTags)

    hook.Run("RPTools_OnPlayerTagsUpdated", targetPlayer, playerTags)
end)

hook.Add( "AddToolMenuCategories", "RPTools Category", function()
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

        local newTagEntry = vgui.Create("DTextEntry", panel)
        newTagEntry:SetPlaceholderText("Enter a new tag name...")
        panel:AddPanel(newTagEntry)

        local btnAdd = vgui.Create("DButton", panel)
        btnAdd:SetText("Add Tag")
        btnAdd.DoClick = function()
            local tag = newTagEntry:GetValue()
            if tag ~= "" then
                net.Start("rptools_add_tag")
                net.WriteString(tag)
                net.SendToServer()
                

                newTagEntry:SetValue("")
            end
        end
        panel:AddPanel(btnAdd)

        local tagsList = vgui.Create("DListView", panel)
        tagsList:SetTall(150)
        tagsList:SetMultiSelect(false)
        tagsList:AddColumn("Tags (Right-click to remove)")
        panel:AddPanel(tagsList)

        tagsList.OnRowRightClick = function(smth, lineID, line)
            local tagToRemove = line:GetValue(1)
            
            -- Petite fenêtre de confirmation native de GMod
            Derma_Query("Do you really want to remove tag : " .. tagToRemove .. " ?", "Confirmation",
                "Yes", function()
                    net.Start("rptools_remove_tag")
                    net.WriteString(tagToRemove)
                    net.SendToServer()
                end,
                "No", function() end
            )
        end

        hook.Add("RPTools_OnTagsUpdated", tagsList, function(self, register)
            if IsValid(self) then
                self:Clear()
                for _, tag in pairs(register) do
                    self:AddLine(string.NiceName(tag))
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

        local plyCombo = vgui.Create("DComboBox", panel)
        plyCombo:SetValue("Select a player...")
        for _, ply in ipairs(player.GetAll()) do
            plyCombo:AddChoice(ply:Nick(), ply)
        end
        panel:AddPanel(plyCombo)

        plyCombo.OnSelect = function(self, index, value, selectedPlayer)
            if IsValid(selectedPlayer) then
                net.Start("rptools_player_tags")
                net.WriteEntity(selectedPlayer)
                net.SendToServer()
            end
        end

        local checkboxContainer = vgui.Create("DPanel", panel)
        checkboxContainer:SetPaintBackground(false)
        panel:AddPanel(checkboxContainer)

        hook.Add("RPTools_OnPlayerTagsUpdated", checkboxContainer, function(self, targetPly, plyOwnedTags)
            if IsValid(self) then
                self:Clear()
                
                local yOffset = 0
                for _, tagName in pairs(RPTools.UI.registerList) do
                    
                    local chk = vgui.Create("DCheckBoxLabel", self)
                    chk:SetPos(0, yOffset)
                    chk:SetText(string.NiceName(tagName))
                    chk:SetDark(true)
                    chk:SizeToContents()

                    local hasTag = false
                    for _, ownedTag in pairs(plyOwnedTags) do
                        if ownedTag == tagName then hasTag = true break end
                    end
                    
                    chk:SetValue(hasTag)

                    chk.OnChange = function(s, state)
                        if state then
                            net.Start("rptools_tag_player")
                        else
                            net.Start("rptools_untag_player")
                        end
                        net.WriteString(tagName)
                        net.WriteEntity(targetPly)
                        net.SendToServer()
                    end

                    yOffset = yOffset + 25
                end
                
                self:SetTall(yOffset)
            end
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