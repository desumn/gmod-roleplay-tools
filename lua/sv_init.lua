
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

util.AddNetworkString("rptools_nuke_player_tags")

util.AddNetworkString("rptools_clear_player_tags")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("RPTools/UI/cl_whisper_ui.lua")
AddCSLuaFile("RPTools/ui/cl_admin_menu.lua")
AddCSLuaFile("sh_commands.lua")

include("RPTools/Utilities/sv_utils.lua")
include("RPTools/Tags/sv_tags.lua")
include("RPTools/Whispers/sv_whispers.lua")

sql.Query([[CREATE TABLE IF NOT EXISTS rptools_tags(
    id TEXT PRIMARY KEY,
    data TEXT
);]])

sql.Query([[PRAGMA foreign_keys = ON;]])


sql.Query([[CREATE TABLE IF NOT EXISTS rptools_player_tags(
    SteamID64 TEXT,
    tagId TEXT,
    PRIMARY KEY (steamid64, tagId),
    FOREIGN KEY (tagId) REFERENCES rptools_tags(id) ON DELETE CASCADE
);]])

RPTools.Tags.loadRegisterFromDB()

