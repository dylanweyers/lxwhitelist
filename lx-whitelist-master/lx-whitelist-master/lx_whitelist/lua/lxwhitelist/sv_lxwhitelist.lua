//-- Read the config file

//-- Pooling net messages

util.AddNetworkString( "lx_wlist_noti" )
util.AddNetworkString( "cl_request_wlist_refresh" )
util.AddNetworkString( "open_wlist_menu" )
util.AddNetworkString( "cl_request_whitelist" )

//-- lx Whitelist Functions

--SET UP SQL TABLE IF NOT ALREADY DONE
local function lx_wlist_createtables()
	if not sql.TableExists( "lxwhitelist" ) or not sql.TableExists( "lxwhitelist_settings" ) then
		MsgC( Color( 255, 0, 0 ), "lxWhitelist Data Tables don't exist!\n", Color(65,65,155), "Attempting to create...\n" )
		sql.Query( "CREATE TABLE lxwhitelist( Steamid TEXT, Job TEXT, Whitelister TEXT )" )
		sql.Query( "CREATE TABLE lxwhitelist_settings( Setting TEXT, Value TEXT ) ")
		if sql.TableExists( "lxwhitelist" ) and sql.TableExists( "lxwhitelist_settings" ) then
			MsgC( Color( 65, 65, 220), "lxWhitelist Data Tables created!\n")
		end
	end
end

--NOTIFY PLAYER
local function lx_wlist_notify( ply, tx, col )
	if not ply then
		return
	end
	if not tx then
		return
	end
	if not col then
		col = Color(255,255,255)
	end
	net.Start( "lx_wlist_noti" )
		net.WriteString( tx )
		net.WriteColor( col )
	net.Send( ply )
end

--UTILITY FUNCTION TO FIND JOB AND RETURN COMMAND/NAME OF JOB
local function lx_wlist_findjob(job,ret)
	if not job then return end
	for k, v in pairs(RPExtraTeams) do
		if v.name == job or string.find(string.lower(v.name), string.lower(job)) or v.command == job or v.jobvar and v.jobvar == job then
			if not ret or ret == "cmd" then
				ret = v.command
			elseif ret == "name" then
				ret = v.name
			end
			return ret
		end
	end
	return false
end

--FIND PLAYER
local function lx_wlist_findply( ply, ret )
	if not ply then
		return
	end
	if tonumber( ply ) and isnumber( tonumber( ply ) ) then
		return ply
	elseif string.find( string.upper(ply), "STEAM_" ) then
		return util.SteamIDTo64( string.upper(ply) )
	elseif isentity(ply) or not string.find( ply, "STEAM_" ) and not isnumber( ply ) then
		for k, v in pairs( player.GetAll() ) do 
			if string.find( string.lower( v:GetName() ), string.lower( ply ) ) then
				if not ret or ret == "ent" then
					return v
				elseif ret == "name" then
					return v:GetName()
				end
			end
		end
	end
end

--RETURN WHETHER OR NOT PLAYER IS WHITELISTED TO JOB
local function lx_whitelisted( ply, job )
	local tempdat = sql.Query( "SELECT Job FROM lxwhitelist WHERE Steamid = "..ply:SteamID64() )
	if not tempdat then return end
	for k,v in pairs(tempdat) do
		if v.Job == job then
			return true
		end
	end
	return false
end

--ADD PLAYER TO WHITELIST
local function lx_add_whitelist( whitelister, ply, job )
	if not whitelister or not table.HasValue( lxwlist.config.ranks, whitelister:GetUserGroup() ) or not ply or not job then
		return
	end
	local sid64
	local plyname
	if isentity(ply) then
		sid64 = tostring(ply:SteamID64()) 
	elseif tonumber(ply) then
		sid64 = tostring(ply)
		ply = player.GetBySteamID64(sid64)
	elseif string.find(ply, "STEAM_") then
		sid64 = tostring(util.SteamIDTo64(ply))
		ply = player.GetBySteamID64(sid64)
	end 
	
	local lx_rpname = sql.Query( "SELECT rpname FROM darkrp_player WHERE uid='"..sid64.."'" )
	if lx_rpname then
		plyname = lx_rpname[1].rpname
	end
	job = lx_wlist_findjob(job)
	if job == false then 
		return
	end
	local tempdat = sql.Query( "SELECT Job FROM lxwhitelist WHERE Steamid='"..sid64.."' AND Job='"..job.."'" )
	local alreadywhitelisted = false
	if tempdat then
		for k, v in pairs( tempdat ) do
			if v.Job == job then
				alreadywhitelisted = true
				lx_wlist_notify( whitelister, "'"..plyname.."' is already whitelisted to this job!", Color(185,25,25) )
				return
			end
		end
	end
	sql.Query("INSERT INTO lxwhitelist( Steamid, Job ) VALUES( '"..sid64.."', '"..job.."')")
	local jobname = lx_wlist_findjob(job,"name")
	lx_wlist_notify( whitelister, "You whitelisted "..plyname.." to "..jobname..".", Color(25,195,25) )
	lx_wlist_notify( ply, "You were whitelisted to "..jobname.." by "..whitelister:GetName() or nil..".", Color(25,195,25) )
end

--REMOVE PLAYER FROM WHITELIST
local function lx_remove_whitelist( unwhitelister, ply, job )
	if not unwhitelister or not table.HasValue( lxwlist.config.ranks, unwhitelister:GetUserGroup() ) or not ply or not job then
		return
	end
	local sid64
	local plyname
	if isentity(ply) then
		sid64 = tostring(ply:SteamID64()) 
	elseif tonumber(ply) then
		sid64 = tostring(ply)
		ply = player.GetBySteamID64(sid64)
	elseif string.find(ply, "STEAM_") then
		sid64 = tostring(util.SteamIDTo64(ply))
		ply = player.GetBySteamID64(sid64)
	end 
	local lx_rpname = sql.Query( "SELECT rpname FROM darkrp_player WHERE uid='"..sid64.."'" )
	if lx_rpname then
		plyname = lx_rpname[1].rpname
	end
	local job = lx_wlist_findjob(job)
	local tempdat = sql.Query( "SELECT Job FROM lxwhitelist WHERE Steamid="..sid64 )
	if tempdat then
		for k, v in pairs(tempdat) do
			if v.Job == job then
				sql.Query( "DELETE FROM lxwhitelist WHERE Steamid='"..sid64.."' AND Job='"..job.."'")
				local jobname = lx_wlist_findjob(job,"name")
				lx_wlist_notify( unwhitelister, "You unwhitelisted "..plyname.." from "..jobname..".", Color(195,25,25) )
				lx_wlist_notify( ply, "You were unwhitelisted from "..jobname.." by "..unwhitelister:GetName()..".", Color(195,25,25) )
				return
			end
		end
		lx_wlist_notify( unwhitelister, "'"..plyname.."' can't be removed if they weren't whitelisted in the first place.", Color( 195, 25, 25 ) )
		return
	end
end

--FUNCTION TO UPDATE WHITELIST'S JOBS (MOSTLY FOR IF CONFIG GETS CHANGED, NEED TO REVERT THE WHITELIST CUSTOMCHECK)
local function lx_wlist_refresh()
	if lxwlist.config.enabled == true then
		for k, v in pairs( RPExtraTeams ) do
			if table.HasValue( lxwlist.config.ignores, v.name ) then
				v.customCheck = nil
				continue
			end
			v.customCheck = function(ply) return lx_whitelisted( ply, v.command ) end
			v.CustomCheckFailMsg = "You are not whitelisted to "..v.name.."!"
		end
	end
	if lxwlist.config.enabled == false then
		for k, v in pairs(RPExtraTeams) do
			v.customCheck = nil
		end
	end
end
//-- Hooks

hook.Add( "Initialize", "create_lxwhitelist_tables", lx_wlist_createtables )

hook.Add( "InitPostEntity", "lxwhitelist_insert_customchecks", lx_wlist_refresh )

hook.Add("PlayerSay", "lx_whitelist_cmd", function(ply,tex)
	if string.sub(string.lower(tex),1,#lxwlist.config.cmd) == string.lower(lxwlist.config.cmd) and table.HasValue( lxwlist.config.ranks, ply:GetUserGroup() ) then
		local args = string.Explode(" ", tex)
		if not args[2] and not args[3] then
			net.Start( "open_wlist_menu" )
			net.Send( ply )
			return
		end
		PrintTable(args)
		if not lx_wlist_findply( args[2] ) or string.len(tostring(args[3])) <= 2 then 
			lx_wlist_notify( ply, "Failed to find player or job. Try using the menu if this occurs again.", Color( 195, 25, 25 ) )
			return
		end
		lx_add_whitelist( ply, lx_wlist_findply( args[2], "ent" ), args[3] )
	end
end )

hook.Add("PlayerSay", "lx_whitelist_uncmd", function(ply,tex)
	if string.sub(string.lower(tex),1,#lxwlist.config.uncmd) == string.lower(lxwlist.config.uncmd) and table.HasValue( lxwlist.config.ranks, ply:GetUserGroup() ) then
		local args = string.Explode(" ", tex)
		if not args[2] or not lx_wlist_findply( args[2] ) or not args[3] or string.len(args[3]) < 2 then 
			lx_wlist_notify( ply, "Failed to find player or job. Try using the menu if this occurs again.", Color( 195, 25, 25 ) )
			return
		end
		lx_remove_whitelist( ply, lx_wlist_findply( args[2] ), args[3] )
	end
end )

net.Receive( "cl_request_wlist_refresh", lx_wlist_refresh )

net.Receive( "cl_request_whitelist", function( len, whitelister )
	local act = net.ReadString()
	local ply = net.ReadEntity()
	local job = net.ReadString()
	if act == "add" then
		lx_add_whitelist( whitelister, ply, job )
	elseif act == "remove" then
		lx_remove_whitelist( whitelister, ply, job )
	end
end ) 

print(sql.LastError())
