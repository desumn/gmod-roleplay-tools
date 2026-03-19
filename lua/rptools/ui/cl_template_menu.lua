

local function openPanel(screenWidth, screenHeight, templates)
    local frame = vgui.Create("DFrame")
    frame:SetSize(math.Clamp(screenWidth * 0.2, 300, 450), math.Clamp(screenHeight * 0.8, 500, screenHeight - 40))
    frame:AlignRight(5)
    frame:CenterVertical()
    frame:SetDraggable(true)
    frame:SetVisible(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()

    local searchBar = vgui.Create("DTextEntry", frame)
    searchBar:SetTall(30)
    searchBar:Dock(TOP)
    searchBar:DockMargin(10, 5, 10, 5)
    searchBar:SetPlaceholderText("Search for a tag...")

    local templateList = vgui.Create("DListView", frame)
    templateList:SetTall(frame:GetTall() * 0.35)
    templateList:Dock(TOP)
    templateList:DockMargin(10, 5, 10, 5)
    templateList:AddColumn("Name")
    for i = 1, 15 do
        templateList:AddLine("Template " .. i)
    end

    local infoPanel = vgui.Create("DPanel", frame)
    infoPanel:SetTall(90)
    infoPanel:SetPaintBackground(false)
    infoPanel:Dock(TOP)
    infoPanel:DockMargin(10, 5, 10, 5)

    infoPanel.Paint = function (self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 100))
    end

    local infoLabel = vgui.Create("DLabel", infoPanel)
    infoLabel:Dock(FILL)
    infoLabel:DockMargin(10, 10, 10, 10)
    infoLabel:SetWrap(true)
    infoLabel:SetText("Je suis une pomme, je me fais manger, c'est ma vie, que voulez-vous? dieu sait pourquoi, je me sens souvent mal à l'idée de me faire dévorer, surtout si on ne me termine pas.")

    local sendButton = vgui.Create("DButton", frame)
    sendButton:SetTall(45)
    sendButton:Dock(BOTTOM)
    sendButton:DockMargin(10, 5, 10, 5)
    sendButton:SetText("Save")

    local editorTitle = vgui.Create("DLabel", frame)
    editorTitle:Dock(TOP)
    editorTitle:SetText("TEMPLATE PARAMETERS")
    editorTitle:SetFont("DermaDefaultBold")
    editorTitle:SetTextColor(Color(180, 180, 180))
    editorTitle:DockMargin(10, 10, 5, 5)

    local editor = vgui.Create("DScrollPanel", frame)
    editor:Dock(FILL)
    editor:DockMargin(5, 0, 5, 0)

    editor.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 50))
    end

    local test1 = vgui.Create("DTextEntry", editor)
    test1:Dock(TOP)
    test1:DockMargin(10, 5, 10, 20)
    test1:SetMultiline(true)
    test1:SetTall(50)
    test1:SetPlaceholderText("Message...")

    local test2 = vgui.Create("DNumSlider", editor)
    test2:Dock(TOP)
    test2:DockMargin(10, 5, 10, 20)
    test2:SetText("Distance")
    test2:SetMinMax(0, 2000)
    test2:SetDecimals(0)

    local test3 = vgui.Create("DCheckBoxLabel", editor)
    test3:Dock(TOP)
    test3:DockMargin(10, 5, 10, 20)
    test3:SetText("Check flag?")

    local test4 = vgui.Create("DTextEntry", editor)
    test4:Dock(TOP)
    test4:DockMargin(10, 5, 10, 20)
    test4:SetPlaceholderText("Tag...")


end

concommand.Add("rptools_menu", function (ply, cmd, args, argStr)
    openPanel(ScrW(), ScrH())
end)