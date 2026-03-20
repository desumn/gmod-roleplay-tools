

local function makeFrame(name)
    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.18, ScrH() * 0.7)
    frame:CenterVertical()
    frame:AlignRight(ScrW() * 0.005)
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:SetTitle("Create Node From Template -- " .. name)
    frame:MakePopup()
    return frame
end

local function makeTitle(name, frame)
    local title = vgui.Create("DLabel", frame)
    title:SetFont("DermaLarge")
    title:SetText(name)
    title:SetTextColor(color_white)
    title:SizeToContents()
    title:SetContentAlignment(5)
    title:SetTall(30)
    title:DockMargin(10, 10, 10, 5)
    title:Dock(TOP)
    return title
end

local function makeDescription(description, frame)
    local descLabel = vgui.Create("DLabel", frame)
    descLabel:SetFont("DermaDefault")
    descLabel:SetText(description)
    descLabel:SetTextColor(Color(180, 180, 180))
    
    descLabel:SetWrap(true)
    descLabel:SetAutoStretchVertical(true)
    
    descLabel:SizeToContents()
    descLabel:SetContentAlignment(5)
    descLabel:DockMargin(10, 0, 10, 10)
    descLabel:Dock(TOP)
    return descLabel
end

local function makeSeparator(frame)
    local separator = vgui.Create("DPanel", frame)
    
    separator:SetTall(2)
    
    separator.Paint = function(self, w, h)
        surface.SetDrawColor(Color(100, 100, 100))
        surface.DrawRect(0, 0, w, h)
    end
    
    
    separator:DockMargin(10, 5, 10, 5)
    separator:Dock(TOP)
    
    return separator
end

local function makeSubmitButton(frame)
    local button = vgui.Create("DButton", frame)
    
    button:SetTall(35)
    
    button:SetText("Create Node")
    
    
    button:SetEnabled(false)
    button:DockMargin(10, 5, 10, 10)
    button:Dock(BOTTOM)
    return button
end

local function makeParameters(parameters, frame)
    local parametersPanel = vgui.Create("DScrollPanel", frame)

    parametersPanel:DockMargin(10, 0, 10, 0)
    parametersPanel:Dock(FILL)
end


local function openPanel(name, description, parameters)
    local frame = makeFrame(name)
    makeTitle(name, frame)
    makeDescription(description, frame)
    makeSeparator(frame)
    makeSubmitButton(frame)
    makeParameters(parameters, frame)
end

concommand.Add("rptools_menu", function (ply, cmd, args, argStr)
    openPanel("Messager",
    "Node that send a chat message once to a nearby player eventually checking for player flags",
    {
        {
            name = "message",
            description = "message to send",
            type = "string",
            required = true
        },
        {
            name = "distance",
            description = "activation distance",
            type = "number",
            required = true,
            default = 200
        },
        {
            name = "flag",
            description = "required flag for activating",
            type = "string",
            required = false
        }
    })
end)