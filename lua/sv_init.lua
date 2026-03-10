
print("[Roleplay Tools] Starting server")

util.AddNetworkString("show_tag_register")
util.AddNetworkString("show_whispers")
util.AddNetworkString("rptools_register_list")

util.AddNetworkString("rptools_add_tag")
util.AddNetworkString("rptools_remove_tag")

util.AddNetworkString("rptools_player_tags")
util.AddNetworkString("rptools_tag_player")
util.AddNetworkString("rptools_untag_player")

util.AddNetworkString("rptools_select_entity")

util.AddNetworkString("rptools_list_whispers")
util.AddNetworkString("rptools_add_whisper")
util.AddNetworkString("rptools_remove_whisper")

util.AddNetworkString("rptools_open_editor")


AddCSLuaFile("cl_init.lua")
AddCSLuaFile("sh_config.lua")
AddCSLuaFile("RPTools/UI/cl_whisper_ui.lua")
AddCSLuaFile("RPTools/ui/cl_admin_menu.lua")

include("sh_config.lua")
include("RPTools/Utilities/sv_utils.lua")
include("RPTools/Tags/sv_tags.lua")
include("RPTools/Whispers/sv_whispers.lua")
