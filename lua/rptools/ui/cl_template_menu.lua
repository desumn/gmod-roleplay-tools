

local function openPanel(screenWidth, screenHeight, templates)
    local frame = vgui.Create("DFrame")
    frame:AlignRight()
    frame:CenterVertical()
    frame:SetSize(300, 150)
    frame:SetTitle("Create a node from a template")
    frame:SetVisible(true)
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
end

concommand.Add("rptools_menu", function (ply, cmd, args, argStr)
    openPanel(ScrW(), ScrH())
end)