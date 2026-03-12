
print("[Roleplay Tools] Starting client")

include("rptools/ui/cl_whisper_ui.lua")
include("rptools/ui/cl_admin_menu.lua")
include("rptools/ui/cl_whisper_editor.lua")
include("rptools/whispers/cl_whispers_cache.lua")

net.Receive("rptools_register_list", function (len, ply)
    RPTools.UI.registerList = net.ReadTable()
end)