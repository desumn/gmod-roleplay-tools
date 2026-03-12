
print("[Roleplay Tools] Starting client")

include("RPTools/UI/cl_whisper_ui.lua")
include("RPTools/UI/cl_admin_menu.lua")
include("RPTools/ui/cl_whisper_editor.lua")
include("RPTools/whispers/cl_whispers_cache.lua")

net.Receive("rptools_register_list", function (len, ply)
    RPTools.UI.registerList = net.ReadTable()
end)