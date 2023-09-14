//-----DO NOT EDIT THESE TWO LINES-----\\
lxwlist = {}
lxwlist.config = {}
//-------------------------------------\\

//-- Whether or not the whitelist system is enabled. True for enabled | False for disabled
lxwlist.config.enabled = true

//-- Cmd = The chat command to use to open the whitelist menu if there are no arguments, or whitelist a player if there are arguments.
//-- For example, if the command is !whitelist, !whitelist alone will open the menu but !whitelist john blacksmith will whitelist john to blacksmith (if the job exists)
//-- Uncmd will always be an argument based command.
lxwlist.config.cmd = "!whitelist"
lxwlist.config.uncmd = "!unwhitelist"

//--Jobs that ignore the whitelist, recommended to set this to your default darkrp job. Set it to the job's NAME.
lxwlist.config.ignores = {
	"Citizen"
}
//-- Ranks = ranks that will be able to whitelist. Only works with ULX for now.
lxwlist.config.ranks = {
	"superadmin",
	"owner"
}

//----------DO NOT TOUCH THE LINES BELOW----------
if SERVER then
	AddCSLuaFile("lxwhitelist/cl_lxwhitelist.lua")
	include("lxwhitelist/sv_lxwhitelist.lua")
end
if CLIENT then
	include("lxwhitelist/cl_lxwhitelist.lua")
end