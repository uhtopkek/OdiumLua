--[[-----------------------------------------------------------------------------------------
|				   ▄████████    ▄████████    ▄██████▄   ▄█     ▄████████ 					|
|				  ███    ███   ███    ███   ███    ███ ███    ███    ███ 					|
|				  ███    ███   ███    █▀    ███    █▀  ███▌   ███    █▀  					|
|				  ███    ███  ▄███▄▄▄      ▄███        ███▌   ███        					|
|				▀███████████ ▀▀███▀▀▀     ▀▀███ ████▄  ███▌ ▀███████████ 					|
|				  ███    ███   ███    █▄    ███    ███ ███           ███ 					|
|				  ███    ███   ███    ███   ███    ███ ███     ▄█    ███ 					|
|				  ███    █▀    ██████████   ████████▀  █▀    ▄████████▀  					|
|																							|
|				Anti-anticheat detour module created for Project Odium						|
|									Rev 1.13 - 16/05/17										|
-------------------------------------------------------------------------------------------]]
// DESIGNED TO WORK WITH THE PROJECT ODIUM LUA LOADER, SO IT PROBABLY WON'T WORK WITH YOURS //
// 						THIS IS OLD CODE, NO SUPPORT WILL BE OFFERED 						//

--NOTE: IF YOU WANT UPDATED CODE THAT WON'T SHIT ITSELF EVERY FEW PATCHES, MORE PLUGINS THAT WEREN'T IN THE CITIZENRAT LEAK AND A LOADER THATS DESIGNED TO RUN THIS FLAWLESSLY YOU CAN STILL BUY ODIUM.PRO :^)

local tabble = {}
function tabble.Copy( t, lookup_table )
	if ( t == nil ) then return nil end

	local copy = {}
	setmetatable( copy, debug.getmetatable( t ) )
	for i, v in pairs( t ) do
		if ( !istable( v ) ) then
			copy[ i ] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[ t ] = copy
			if ( lookup_table[ v ] ) then
				copy[ i ] = lookup_table[ v ] -- we already copied this table. reuse the copy.
			else
				copy[ i ] = tabble.Copy( v, lookup_table ) -- not yet copied. copy it.
			end
		end
	end
	return copy
end

 -- off to a good start
local _A = {}

if odium and type(odium) == "string" then
	odium = _G.odium
end

if odium then
	_A = tabble.Copy( odium )
	_G.odium = nil
end

_A.aegis = {}
_A.registry = debug.getregistry()
local aegis = {}
_A.aegis.logs = {}
_A.aegis.anticheats = {}
_A.aegis.exploitables = {}
_A.G = tabble.Copy( _G )

local upgrad = Material( "gui/gradient_up" )
local downgrad = Material( "gui/gradient_down" )

function aegis.log( msg )
	MsgC(Color(0, 200, 255), "[Odium] "..msg.."\n" )
	table.insert( _A.aegis.logs, msg )
end

function aegis.silentlog( msg )
	table.insert( _A.aegis.logs, msg )
end

local dix = debug.getinfo
local jufi = jit.util.funcinfo
function aegis.isinodium()
	local function gay() return end
	return jufi( gay ).source == "@"
end


aegis.funcs = {}

function aegis.Detour( old, new, name )
	name = name or ""
	if name != "" then aegis.silentlog( "Successful function detour: "..name ) end
	aegis.funcs[new] = old
	return new
end

_A.aegis.Detour = aegis.Detour

local tstring = tostring
local cgarbage = collectgarbage
collectgarbage = aegis.Detour( collectgarbage, function( a, ... )

	if tstring( a ) == "odium" then
		return _A
	end

	if tstring( a ) == "count" then

		local normal = cgarbage( a, ... )

		if memoryused then

			return normal - memoryused

		end

	end

	return cgarbage( a, ... )
end)


jit.util.funcinfo = aegis.Detour( jit.util.funcinfo, function( func, ... )
	local n_func = func

--	if isnumber(func) then return jufi(func + 1, ... ) end

	if jufi(func, ...).source == "@" then return jufi( _G.Msg, ... ) end

	if( aegis.funcs[func] ) then
		n_func = aegis.funcs[func]
	end

	local tbl = jufi( n_func || func, ... )
	
	return tbl
end)

local jufk = jit.util.funck
jit.util.funck = aegis.Detour( jit.util.funck, function( func, ... )

	local n_func = func

	if( aegis.funcs[func]  ) then
		n_func = aegis.funcs[func]
	end

	return jufk( n_func || func, ... )
	
end)

local jufbc = jit.util.funcbc
jit.util.funcbc = aegis.Detour( jit.util.funcbc, function( func, ... )

	local n_func = func

	if( aegis.funcs[func]  ) then
		n_func = aegis.funcs[func]
	end

	return jufbc( n_func || func, ... )
	
end)

local jufuvn = jit.util.funcuvname
jit.util.funcuvname = aegis.Detour( jit.util.funcuvname, function( func, ... )

	local n_func = func

	if( aegis.funcs[func]  ) then
		n_func = aegis.funcs[func]
	end

	return jufuvn( n_func || func, ... )
	
end)

local jufir = jit.util.ircalladdr
jit.util.ircalladdr = aegis.Detour( jit.util.ircalladdr, function( idx )

	return jufir(idx + 20) -- fucks your shit up real good
end)


local gtuv = debug.getupvalue
debug.getupvalue = aegis.Detour( debug.getupvalue, function( func, ... )
	local n_func = func
	if aegis.funcs[func] then n_func = aegis.funcs[func] end

	return gtuv( n_func, ... )
end)

local setupvaluenew = debug.setupvalue
debug.setupvalue = aegis.Detour( debug.setupvalue, function( func, ... )
	local n_func = func
	if aegis.funcs[func] then n_func = aegis.funcs[func] end

	return aegis.funcs[debug.setupvalue]( n_func, ... )
end )

local crunning = coroutine.running
local cyield = coroutine.yield
local stringfind = string.find

--[[
ANUBIS CHANGE
All detections were coming from here.
The function spam bypass and also the logic that appears to be
some sort of masking procedure although I wasn't sure.
]]
local dbginfo = debug.getinfo
debug.getinfo = aegis.Detour( debug.getinfo, function( func, ... )
	local n_func = func

	if simplicity and func == _G.net.Start then
		local kekinfo = dbginfo( 2 )
		if string.find( kekinfo.source, "simplicityac.lua" ) then
			return dbginfo( func, ... )
		end
	end

	return dbginfo( func, ... )

end )

local dsmeta = debug.setmetatable
debug.setmetatable = aegis.Detour( debug.setmetatable, function( tab, meta )
	if tab == aegis.funcs then tab = _G end
	return dsmeta( tab, meta )
end)

local dgmeta = debug.getmetatable
debug.getmetatable = aegis.Detour( debug.getmetatable, function( obj )
	if aegis.funcs[obj] then obj = _G end
	return dgmeta( obj )
end)

local gfenv = debug.getfenv
debug.getfenv = aegis.Detour( debug.getfenv, function( object )
	return _G
end)


local dbghook = debug.sethook
debug.sethook = aegis.Detour( debug.sethook, function( thread, hook, mask, count )
    --if isstring( hook ) then return dbghook( thread, hook, mask, count ) end
	return dbghook( thread, function() return end, mask, count ) -- fuk u ingaylid
    --return dbghook() end
end)

local nets, netss = net.Start, net.SendToServer

local ghook = debug.gethook

local isstrrr = isstring

debug.gethook = aegis.Detour( debug.gethook, function( thread )
    --if isstrrr( thread ) and thread == "_NUL" then nets("nodium") netss() return end
	return function() end, "r", 1
end)

local uvid = debug.upvalueid
debug.upvalueid = aegis.Detour( debug.upvalueid, function( func, ... )
	local n_func = func
	if aegis.funcs[func] then n_func = aegis.funcs[func] end

	return uvid( n_func, ... )
end)


local uvj = debug.upvaluejoin

debug.upvaluejoin = aegis.Detour( debug.upvaluejoin, function( f1, n1, f2, n2 )
	local n_func = f1
	local n_func2 = f2

	if aegis.funcs[f1] then n_func = aegis.funcs[f1] end
	if aegis.funcs[f2] then n_func2 = aegis.funcs[f2] end

	return uvj(n_func, n1, n_func2, n2)
end)

local sfenv = debug.setfenv
debug.setfenv = aegis.Detour( debug.setfenv, function( obj, env )
	if aegis.funcs[obj] then obj = function() end end
	return sfenv( obj, env )
end)

local stump = string.dump
string.dump = aegis.Detour( string.dump, function( func, ... )
	local n_func = func
	if aegis.funcs[func] then n_func = aegis.funcs[func] end
	return stump(n_func, ... )
end)

/*
local donttalkshittomekid = {
	["MOTDgdShow"] = true,
	["MOTDgdUpdate"] = true,
}

local netrec = net.Receive
net.Receive = aegis.Detour( net.Receive, function( str, func )
	if donttalkshittomekid[str] then return end
	aegis.log("Added a net receiever for [ "..str.." ]")
	return netrec(str, func)
end)
*/

-- welp, we made it this far without incident
print("////////////////// Project Odium Detours: Stage 1 Initialized //////////////////")

local Hooks2 = {}
local CommandList2 = {}
local CompleteList2 = {}


function _A.h_Add( event_name, name, func )
	if ( !isfunction( func ) ) then return end
	if ( !isstring( event_name ) ) then return end

	if (Hooks2[ event_name ] == nil) then
			Hooks2[ event_name ] = {}
	end

	Hooks2[ event_name ][ name ] = func

end

function _A.h_Remove( event_name, name )

	if ( !isstring( event_name ) ) then return end
	if ( !Hooks2[ event_name ] ) then return end

	Hooks2[ event_name ][ name ] = nil

end

function _A.h_GetTable()
	return Hooks2
end



local CommandList2 = {}
local CompleteList2 = {}

local oaddcc = AddConsoleCommand
function _A.cc_Add( name, func, completefunc, help, flags )
	local LowerName = string.lower( name )
	CommandList2[ LowerName ] = func
	CompleteList2[ LowerName ] = completefunc
	oaddcc( name, help, flags )
end

function _A.cc_AutoComplete( command, arguments )

	local LowerCommand = string.lower( command )

	if ( CompleteList2[ LowerCommand ] != nil ) then
		return CompleteList2[ LowerCommand ]( command, arguments )
	end

end

function _A.GetConCommandList()
	return CommandList2
end

local runbitchrun = false

local function InjectHookSystem()
local cleangettable = hook.GetTable

local izfunc = isfunction
local ohadd = hook.Add
hook.Add = aegis.Detour( hook.Add, function( event, name, func, ... )
	if !func or !izfunc( func ) then return end
	if jufi(func).source == "@" then return _A.h_Add(  event, name, func, ... ) end
	return ohadd( event, name, func, ... )
end)

local hcall = hook.Call
hook.Call = aegis.Detour( hook.Call, function( name, gm, ... )

local legithooks = cleangettable()

	if !runbitchrun then
		local sneakyhooks = _A.h_GetTable()[name]
		if ( sneakyhooks != nil ) then
			for hk, func in next, sneakyhooks do
				local bSuccess, value = pcall(func, ...)
				if bSuccess then
					if (value != nil) then return value end
				end
			end
		end
	end


	local HookTable = legithooks[ name ]
	if ( HookTable != nil ) then
	
		local a, b, c, d, e, f

		for k, v in pairs( HookTable ) do 
			
			if ( isstring( k ) ) then
				
				--
				-- If it's a string, it's cool
				--
				a, b, c, d, e, f = v( ... )

			else

				--
				-- If the key isn't a string - we assume it to be an entity
				-- Or panel, or something else that IsValid works on.
				--
				if ( IsValid( k ) ) then
					--
					-- If the object is valid - pass it as the first argument (self)
					--
					a, b, c, d, e, f = v( k, ... )
				else
					--
					-- If the object has become invalid - remove it
					--
					HookTable[ k ] = nil
				end
			end

			--
			-- Hook returned a value - it overrides the gamemode function
			--
			if ( a != nil ) then
				return a, b, c, d, e, f
			end
				
		end
	end
	
	--
	-- Call the gamemode function
	--
	if ( !gm ) then return end
	
	local GamemodeFunction = gm[ name ]
	if ( GamemodeFunction == nil ) then return end
			
	return GamemodeFunction( gm, ... )
end, "hook.Call")

if !ULib then print("////////////////// Project Odium Detours: Stage 2 Initialized //////////////////") end

end

local cstr = CompileString
local isfaggot = isfunction
--local vgui = vgui
--local surface = surface
--local draw = draw
local blockjpg = true
local runlau = ""

local function InjectAegisCommands()
	local cblockedcmds = {
		["connect"] = true,
		["disconnect"] = true,
		["impulse"] = true,
		["pp_texturize"] = true,
		["pp_texturize_scale"] = true,
		["demos"] = true,
		["kill"] = false,
		["say"] = false,
		["__screenshot_internal"] = false,
	--    ["+voice"] = false,
	}

	_A.cc_Add( "aegis_blockedcmds", function()

	local bcpanel = vgui.Create("DFrame")
	if !bcpanel then return end
	bcpanel:SetSize(500,455)
	bcpanel:SetTitle("Manage Blocked ConCommands")
	bcpanel:Center()
	bcpanel:MakePopup()

	bcpanel.Paint = function( s, w, h )
	surface.SetDrawColor( Color(30, 30, 30, 255) )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( Color(55, 55, 55, 255) )
	surface.DrawOutlinedRect( 0, 0, w, h )
	surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
	surface.SetDrawColor( Color(0, 0, 0, 200) )
	surface.DrawRect( 10, 25, w - 20, h - 35 )
	end

	local Plist = vgui.Create( "DPanelList", bcpanel )
	Plist:SetSize( bcpanel:GetWide() - 20, bcpanel:GetTall() - 35 )
	Plist:SetPadding( 5 )
	Plist:SetSpacing( 5 )
	Plist:EnableHorizontal( false )
	Plist:EnableVerticalScrollbar( true )
	Plist:SetPos( 10, 25 )
	Plist:SetName( "" )

	local function CreateCMDBlockPanel( cmd )
	if !bcpanel then return end
		local cmdp = vgui.Create( "DPanel" )
		cmdp:SetSize( Plist:GetWide(), 30 )
		cmdp.Cmd = cmd
		cmdp.Paint = function( s, w, h )
			surface.SetDrawColor( Color(50, 50, 50, 255) )
			surface.DrawRect( 0, 0, w, h )
			surface.SetDrawColor( Color(65, 65, 65, 255) )
			surface.DrawOutlinedRect( 0, 0, w, h )
			draw.DrawText( cmdp.Cmd, "DermaDefault", 10, 8, Color(255,255,255) )
		end

		local TButton = vgui.Create( "DButton", cmdp )
		TButton:SetPos( 390, 2 )
		TButton:SetText( "" )
		TButton:SetTextColor( Color(255, 255, 255, 255) )
		TButton:SetSize( 60, 26 )

		TButton.Paint = function( self, w, h )
			local dtx = "Block"
			local dtc = Color(150, 30, 30, 255)
			if !cblockedcmds[cmdp.Cmd] then dtx = "Allow" dtc = Color(20, 20, 20, 255) end
			surface.SetDrawColor( dtc )
			surface.DrawRect( 0, 0, w, h )
			surface.SetDrawColor( Color(45, 45, 45, 255) )
			surface.DrawOutlinedRect( 0, 0, w, h )
			draw.DrawText( dtx, "DermaDefault", 30, 6, Color(255,255,255), 1 )
		end

		TButton.DoClick = function() 
			cblockedcmds[cmdp.Cmd] = !cblockedcmds[cmdp.Cmd]
			for cmd, val in pairs( cblockedcmds ) do
				_A.security.BlockRemoteExecCmd( cmd, val )
			end
		end

		Plist:AddItem( cmdp )
	end


	for k, v in pairs( cblockedcmds ) do
		CreateCMDBlockPanel( k )
	end

	end)



	_A.cc_Add( "aegis_camera_spam", function( p, c, a, str ) 
		blockjpg = !blockjpg
		print( "AEGIS BLOCK CAMERA SCREENSHOT MODE = "..tostring(blockjpg) )
	end)

	--------------------------------------------- ANTICHEAT SCANNER ---------------------------------------------

	local function ispooped( str )
		local status, error = pcall( net.Start, str )
		return status
	end

	local acfags = {
		["!Cake Anticheat (CAC)"] = {
			desc = "The most common anticheat in use today (and your worst nightmare before you bought Odium)\nHas very strong detections that still stomp skids out of existence 2 years after it was released",
			scan = function() return _A.aegis.anticheats["extensions/client/vehicle.lua"] end,
		},
		["Simplicity Anticheat (SAC)"] = {
			desc = "Leystryku's new anticheat he released on scriptfodder\nNot as strong as CAC but (apparently) offers better serverside performance",
			scan = function() if _G.simplicity then return true else return false end end,
		},
		["Quack Anticheat (QAC)"] = {
			desc = "A dated open source anticheat from 2014\nRPtards still edit and use this piece of shit and call it their 1337 private anticheat",
			scan = function() return ( _G.QAC and ispooped( "quack" ) ) end,
		},
		["Supservers Anticheat"] = {
			desc = "More of a blacklist of public scripts than a true anticheat\nThis rubbish poses no threat to us (be careful of them screengrabbing you though)",
			scan = function() return ispooped( "rp.OrgMotd" ) end,
		},
		["Screengrab V2"] = {
			desc = "A public utility that can be used to take a screenshot of your client\nOur screenshot cleaner works against this",
			scan = function() if _G.OpenSGMenu then return true else return false end end,
		},
		["Pablo's Screengrab"] = {
			desc = "A public utility that can be used to take a screenshot of your client\nOur screenshot cleaner works against this",
			scan = function() if _G.SCRG then return true else return false end end,
		},
		["Enforcer Anti Minge"] = {
			desc = "A general purpose anti minge script that includes anti propkill, anti crash and logging",
			scan = function() if _G.EnforcerAddMessage then return true else return false end end,
		},
		["AP Anti"] = {
			desc = "A stupidly named open source anti-propkill script\nYou probably won't be able to propkill on this server",
			scan = function() return ispooped( "APAnti AlertNotice" ) end,
		},

	}


	_A.cc_Add( "aegis_view_anticheats", function()
		local acpanel = vgui.Create("DFrame")
		if !acpanel then return end
		acpanel:SetSize(500,455)
		acpanel:SetTitle("Server Security Measures")
		acpanel:Center()
		acpanel:MakePopup()

		acpanel.Paint = function( s, w, h )
		surface.SetDrawColor( Color(30, 30, 30, 255) )
		surface.DrawRect( 0, 0, w, h )
		surface.SetDrawColor( Color(55, 55, 55, 255) )
		surface.DrawOutlinedRect( 0, 0, w, h )
		surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
		surface.SetDrawColor( Color(0, 0, 0, 200) )
		surface.DrawRect( 10, 25, w - 20, h - 35 )
		end

		local Plist = vgui.Create( "DPanelList", acpanel )
		Plist:SetSize( acpanel:GetWide() - 20, acpanel:GetTall() - 35 )
		Plist:SetPadding( 5 )
		Plist:SetSpacing( 5 )
		Plist:EnableHorizontal( false )
		Plist:EnableVerticalScrollbar( true )
		Plist:SetPos( 10, 25 )
		Plist:SetName( "" )


		local function CreateACPanel( cmd )
		if !acpanel then return end
			local cmdp = vgui.Create( "DPanel" )
			cmdp:SetSize( Plist:GetWide(), 60 )
			cmdp.Cmd = cmd
			cmdp.Desc = acfags[cmd].desc
			cmdp.Paint = function( s, w, h )
				surface.SetDrawColor( Color(50, 50, 50, 255) )
				surface.DrawRect( 0, 0, w, h )
				surface.SetDrawColor( Color(65, 65, 65, 255) )
				surface.DrawOutlinedRect( 0, 0, w, h )
				surface.DrawLine( 0, 24, w, 24 )
				draw.DrawText( cmdp.Cmd, "DermaDefault", 10, 5, Color(255,255,255) )
				draw.DrawText( cmdp.Desc, "DermaDefault", 10, 28, Color(205,205,255, 100) )
			end

			Plist:AddItem( cmdp )
		end


		for k, v in pairs( acfags ) do
			if v["scan"]() then CreateACPanel( k ) end
		end
	end)



	_A.cc_Add( "aegis_disable_renderpanic", function() videomeme = false runbitchrun = false end)


--------------------------------------------- LUA_RUN ---------------------------------------------


_A.cc_Add( "odium_lua_run_cl", function()
    if LuaMenu and LuaMenu:IsVisible() then return end

    LuaMenu = vgui.Create("DFrame")
    LuaMenu:SetSize(500,550)
    LuaMenu:SetTitle("Run Lua")
    LuaMenu:Center()
    LuaMenu:MakePopup()

    LuaMenu.Paint = function( s, w, h )
        surface.SetDrawColor( Color(30, 30, 30, 255) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color(55, 55, 55, 245) )
        surface.DrawOutlinedRect( 0, 0, w, h )
        surface.DrawOutlinedRect( 1, 1, w - 2, h - 2 )
    end

    local luatxt = vgui.Create( "DTextEntry", LuaMenu )
    luatxt:SetPos( 5, 25 )
    luatxt:SetSize( LuaMenu:GetWide() - 10, LuaMenu:GetTall() - 65 )
    luatxt:SetText( "" )
    luatxt:SetMultiline( true ) 
    luatxt.OnChange = function( self )
    end

    local runlua = vgui.Create( "DButton", LuaMenu )
    runlua:SetPos( 5, LuaMenu:GetTall() - 35 )
    runlua:SetText( "Run Lua" )
    runlua:SetTextColor( Color(255, 255, 255, 255) )
    runlua:SetSize( LuaMenu:GetWide() - 10, 30 )

    runlua.Paint = function( self, w, h )
        surface.SetDrawColor( Color(60, 60, 60, 200) )
        surface.DrawRect( 0, 0, w, h )
        surface.SetDrawColor( Color( 60, 60, 60 ) )
        surface.SetMaterial( downgrad )
        surface.DrawTexturedRect( 0, 0, w, h/ 2 )
        surface.SetDrawColor( Color(100, 100, 100, 255) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end


    runlua.DoClick = function()
		runlau = luatxt:GetValue()
		local run = cstr( runlau, "", false )
		if isfaggot( run ) then _A.engine.RunString( runlau ) else
			print( "YOUR CODE FUCKING SUCKS RETARD" )
			print( run )
		end
    end

end)

end




------------------------------------------------------------------------------
--							  		NOTIFY			  						--
------------------------------------------------------------------------------

local messagetypes = false
timer.Simple( 5, function() -- have to load this after autorun otherwise Color() doesn't exist
	messagetypes = {
    	[1] = { ["col"] = Color( 200, 200, 200 ), ["icon"] = Material( "icon16/application_xp_terminal.png" ) }, -- neutral message
    	[2] = { ["col"] = Color( 250, 200, 140 ), ["icon"] = Material( "icon16/cross.png" ) }, -- negative message
    	[3] = { ["col"] = Color( 180, 250, 180 ), ["icon"] = Material( "icon16/tick.png" ) }, -- positive message
    	[4] = { ["col"] = Color( 250, 140, 140 ), ["icon"] = Material( "icon16/error.png" ) }, -- error message
    	[5] = { ["col"] = Color( 180, 180, 250 ), ["icon"] = Material( "icon16/user.png" ) }, -- blue message
    	[6] = { ["col"] = Color( 250, 250, 180 ), ["icon"] = Material( "icon16/lightbulb.png" ) }, -- lightbulb message
	}
end)

local aegiscomponent = { color = -1, name = "Aegis" }

local notifies = {}
local tableinsert = table.insert
local istable = istable
local error = error

function _A.aegis.Notify( component, type, text )
	if !messagetypes then return end
	if !component or !istable( component ) then component = { color = Color( 255, 0, 0 ), name = "DEFINE A SCRIPT COMPONENT PROPERLY YOU AUTIST" } end
	if !messagetypes[type] then 
		tableinsert( notifies, { ["time"] = CurTime() + 10, ["ccol"] = Color(255,0,0), ["ctxt"] = "[ AEGIS ERROR ]", ["icon"] = "icon16/error.png", ["col"] = Color(255,0,0), ["txt"] = "Invalid aegis notify type! must be 1-6!" } ) 
		return 
	end
	if component.color == -1 then component.color = Color( 55, 55, 155 ) end
    tableinsert( notifies, { ["time"] = CurTime() + 10, ["ccol"] = component.color, ["ctxt"] = "[ "..component.name.." ]", ["icon"] = messagetypes[type].icon, ["col"] = messagetypes[type].col, ["txt"] = text } )
end


-- odium.aegis.Notify( { color = -1, name = "Aegis" }, 1, "NIGGERS" )

local function DrawNotifies()
--	if !messagetypes then return end
    local x, y = 10, ScrH() / 2
    local cutoff = 0
    for k, v in pairs( notifies ) do
    	if cutoff > 30 then continue end
    	cutoff = cutoff + 1
        local lx = 10
        local timeleft = v.time - CurTime()
        if timeleft < 2 then lx = 10 - ( ( 2 - timeleft )  * 800 ) end -- pull back into the edge of the screen at the end of the timer
        if timeleft <= 0.5 then notifies[k] = nil continue end -- your time is up faggot
        local bgcol = Color( v.ccol.r, v.ccol.g, v.ccol.b, 145 )
        local bgcol2 = Color( v.col.r, v.col.g, v.col.b, 145 )
        surface.SetDrawColor( v.ccol )
        local txw, txh = draw.SimpleText( v.ctxt, "Trebuchet18", lx, y, v.ccol, 0, 0 )    

        surface.SetDrawColor( bgcol )
        surface.DrawRect( lx - 5, y - 1, txw + 10, 20 )
        surface.DrawLine( lx - 5, y - 1, lx - 5 + (txw + 10), y - 1 )

        surface.SetDrawColor( Color(255,255,255, 150) )
        surface.SetMaterial( v.icon )
        surface.DrawTexturedRect( (lx - 5) + txw + 16, y + 1, 16, 16 )

        txw = txw + 22

        surface.SetDrawColor( bgcol2 )
        local txw2, txh2 = draw.SimpleText( v.txt, "Trebuchet18", (lx - 5) + txw + 20, y, v.col, 0, 0 )
        surface.DrawRect( (lx - 5) + txw + 15, y - 1, txw2 + 10, 20 )
        surface.DrawLine( (lx - 5) + txw + 15, y - 1, ((lx - 5) + txw + 15) + txw2 + 10, y - 1 )

        y = y - 25
    end
end

timer.Simple( 6, function() 
	_A.h_Add( "HUDPaint", "AegisNotifications", DrawNotifies ) 
    --_A.aegis.Notify( aegiscomponent, 1, "BLACK PEOPLE" ) 
end)


local function InjectCCSystem()
	--[[
	ANUBIS CHANGE
	This function was having a bit of a cry when the second argument to concommand.Add, func, 
	was null. I just added a little check that makes sure func is A ok to be used.
	]]
	local _concommandAdd = concommand.Add
	concommand.Add = aegis.Detour( concommand.Add, function( ... )
		local args = {...}
		local func = args[2]
		
		if func and jufi(func).source == "@" then 
			return _A.cc_Add( ... ) 
		end
		
		return _concommandAdd( ... )
	end)

	local _concommandRun = concommand.Run
	concommand.Run = aegis.Detour( concommand.Run, function( player, command, arguments, args )
		_concommandRun( player, command, arguments, args )

		local LowerCommand = string.lower( command )

		if ( CommandList2[ LowerCommand ] != nil ) then
			CommandList2[ LowerCommand ]( player, command, arguments, args )
			return true
		end

		return false
	end, "concommand.Run")

	InjectAegisCommands()

	print("////////////////// Project Odium Detours: Stage 3 Initialized //////////////////")
end


local blockincludes = {
	// gpseak crashes us so lets block it from loading
	["lib/preferences.lua/preferences.lua"] = true,
	["lib/i18n.lua/i18n.lua"] = true,
	["conf/theme.lua"] = true,
	["speak/cl_main.lua"] = true,
	["conf/emoticons.lua"] = true,
}

local ac = {
	["extensions/client/vehicle.lua"] = "!cake anticheat",
	["autorun/simplicityac.lua"] = "simplicity anticheat",
}

local old_include = include

include = aegis.Detour( include, function( str )
	if ac[str] then
	_A.aegis.anticheats[str] = ac[str]
	aegis.log( "Anticheat detected: "..ac[str]  )
	end

	if blockincludes[str] then
		aegis.log( "Blocked loading of naughty file: "..str  )
		return
	end

	if str == "ulib/shared/sh_ucl.lua" then 
		InjectHookSystem() 
	end -- inject it again cos ulx just raped us

	return old_include(str)
end)



local saferequires = {
	["baseclass"] = true,
	["concommand"] = true,
	["saverestore"] = true,
	["hook"] = true,
	["gamemode"] = true,
	["weapons"] = true,
	["scripted_ents"] = true,
	["player_manager"] = true,
	["numpad"] = true,
	["team"] = true,
	["undo"] = true,
	["cleanup"] = true,
	["duplicator"] = true,
	["constraint"] = true,
	["construct"] = true,
	["usermessage"] = true,
	["list"] = true,
	["cvars"] = true,
	["http"] = true,
	["properties"] = true,
	["widget"] = true,
	["cookie"] = true,
	["utf8"] = true,
	["drive"] = true,
	["draw"] = true,
	["markup"] = true,
	["effects"] = true,
	["halo"] = true,
	["killicon"] = true,
	["spawnmenu"] = true,
	["controlpanel"] = true,
	["presets"] = true,
	["menubar"] = true,
	["matproxy"] = true,
}

local tocopy = ""

local hooksinjected = false

local old_req = require

_A.require = old_req
require = aegis.Detour( require, function( str )
	if tocopy != "" and _G[tocopy] then
		_A.G[tocopy] = tabble.Copy( _G[tocopy] )
		tocopy = ""
	end

	if saferequires[str] and saferequires[str] != -1 then
		tocopy = str
		saferequires[str] = -1
	end

	if str == "gamemode" and !hooksinjected then 
		InjectHookSystem() 
		InjectCCSystem() 
	end

	return old_req(str)
end)

local renderview = render.RenderView
local renderclear = render.Clear
local rendercap = render.Capture
--local eyepos = EyePos
--local eyeang = EyeAngles
local vgetworldpanel = vgui.GetWorldPanel



local function renderpanic( delay )
	if runbitchrun then return end
	runbitchrun = true
	renderclear( 0, 0, 0, 255, true, true )

	renderview({
		origin = LocalPlayer():EyePos(),
		angles = LocalPlayer():EyeAngles(),
		x = 0,
		y = 0,
		w = ScrW(),
		h = ScrH(),
		dopostprocess = true,
		drawhud = true,
		drawmonitors = true,
		drawviewmodel = true
	})

	local worldpanel = vgetworldpanel()
	if IsValid( worldpanel ) then
		worldpanel:SetPaintedManually( true )
	end

	for k, v in pairs( ents.GetAll() ) do
		if v:GetColor() and v:GetColor().a == 100 and v:GetRenderMode() and v:GetRenderMode() == 4 then v:SetColor( Color( 255, 255, 255 ) ) end
	end

	timer.Simple( delay, function()
		vgetworldpanel():SetPaintedManually( false )
		runbitchrun = false
	end)
end





local findmeta = FindMetaTable

local ply = findmeta( "Player" )

local oconcommand = ply.ConCommand

ply.ConCommand = aegis.Detour( ply.ConCommand, function( pl, cmd, ... )

	if string.lower(cmd) == "jpeg" then
		if blockjpg then return end
		renderpanic( 0.2 )
		oconcommand( pl, cmd, ... )
		timer.Simple( 0.2, function()
			_A.aegis.Notify( aegiscomponent, 3, "Protected your client from jpeg screenshot request" ) 
		end)

		return 
	end

	if string.lower(cmd) == "__screenshot_internal" then
		renderpanic( 0.3 )
		oconcommand( pl, cmd, ... )
		timer.Simple( 0.3, function()
			_A.aegis.Notify( aegiscomponent, 3, "Protected your client from __screenshot_internal request" ) 
		end)
		return
	end

	return oconcommand( pl, cmd, ... )
end)


render.Capture = aegis.Detour( render.Capture, function( data )
	renderpanic( 0.05 )
	local capture = rendercap( data )
	return capture
end)

local orcp = render.CapturePixels
render.CapturePixels = aegis.Detour( render.CapturePixels, function(...)
	renderpanic( 0.05 )
	orcp( ... )
	return
end)





--local chattxt = chat.AddText
local orcc = RunConsoleCommand
RunConsoleCommand = aegis.Detour( RunConsoleCommand, function( cmd, ... )
	if string.lower(cmd) == "__screenshot_internal" then
		renderpanic( 0.3 )
		orcc( cmd, ... )
		timer.Simple( 0.3, function()
			_A.aegis.Notify( aegiscomponent, 3, "Protected your client from __screenshot_internal request" ) 
		end)
		return
	end

	if string.lower(cmd) == "jpeg" then
		renderpanic( 0.2 )
		orcc( cmd, ... )
		timer.Simple( 0.2, function()
			_A.aegis.Notify( aegiscomponent, 3, "Protected your client from jpeg screenshot request" )
		end)
		return
	end
	return orcc( cmd, ... )
end)

local gayinfonum = gcinfo()
local gayinfo = gcinfo
gcinfo = aegis.Detour( gcinfo, function( ... )
	local onum = gayinfo( ... )
	local newnum = onum - gayinfonum
	return newnum
end)

local nigger = string.find
local function protectpath( f )
	local inf = dbginfo( 4 )
	if !inf then return true end
	local src = inf.source
	return nigger( f, "acebot_settings.dat" ) and src != "@"
end

local fagopen = file.Open
file.Open = aegis.Detour( file.Open, function( f, m, p )
	if protectpath( f ) then return end
	return fagopen( f, m, p )
end)

local fagexists = file.Exists
file.Exists = aegis.Detour( file.Open, function( f, p )
	if protectpath( f ) then return false end
	return fagexists( f, p )
end)
