TOOL.Category = "RPTools"
TOOL.Name = "Node Spawner"


if CLIENT then
    local function updateTemplates(templateList, templates)
        templateList:Clear()
        for _, template in pairs(templates) do
            local line = templateList:AddLine(string.NiceName(template.name), template.description)
            line.name = template.name
        end
    end
    
    function TOOL.BuildCPanel(panel)
        panel:Help("1. Select a template.\n2. Configure the template.\n3. Spawn a node from this template.")
        
        local templateList = vgui.Create("DListView")
        templateList:SetTall(80)
        templateList:SetMultiSelect(false)
        templateList:AddColumn("Template Name")
        
        updateTemplates(templateList, RPTools.Templating.ClientCache)
        
        hook.Add("RPTools_TemplateSync", templateList, function (self, templates)
            updateTemplates(self, templates)
        end)
        
        local configPanel = vgui.Create("DPanel", panel)
        
        configPanel:SetSize(0, 0)
        configPanel.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(45, 48, 55, 220))
        end
        
        templateList.OnRowSelected = function (self, index, row)
            RPTools.UI.OpenTemplateMenu(configPanel, RPTools.Templating.GetTemplateFromClientCache(row.name))
            configPanel:InvalidateLayout(true)
            configPanel:SizeToChildren(false, true)
            
            for _, child in ipairs(configPanel:GetChildren()) do
                print(child:GetClassName(), child:GetName(), child:GetTall())
            end
        end
        
        panel:AddItem(templateList)
        panel:AddItem(configPanel)
        
        
    end

    function TOOL:DrawHUD()
        
    end

    
end

function TOOL:LeftClick(tr)
    if CLIENT then
        if RPTools.UI.CurrentTemplate == "" then
            notification.AddLegacy("Please configure a template first", NOTIFY_ERROR, 3)
            surface.PlaySound("buttons/button10.wav")
            return false
        end
        local name = RPTools.UI.CurrentTemplate
        local params = RPTools.UI.CurrentParams

        RPTools.Network.SendToServer(RPTools.Network.MSG_TYPE.CREATE_FROM_TEMPLATE, function ()
            net.WriteString(name)
            net.WriteTable(params)
            net.WriteVector(tr.HitPos)
        end)
        return true
    end
    return true
end