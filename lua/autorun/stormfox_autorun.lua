StormFox = {}
StormFox.Version = 1.124
StormFox.WorkShopVersion = false--game.IsDedicated()
-- Skypaint creation fix.
local con = GetConVar("sf_disableskybox")
if not con or not con:GetBool() then
	RunConsoleCommand("sv_skyname", "painted")
end

--if true then return end
-- Reload support
	hook.Add("InitPostEntity","StormFox - CallPostEntitiy",function()
		_STORMFOX_POSTENTIY = true
		hook.Call("StormFox - PostEntity")
	end)
	if _STORMFOX_POSTENTIY then
		timer.Simple(1,function()
			hook.Call("StormFox - PostEntity")
		end)
	end

-- Add configs
	local function AddConVar(str,default,helptext)
		if ConVarExists(str) then return end
		CreateConVar(str,default, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, helptext)
	end
	AddConVar("sf_timespeed",1,"The minutes of gametime pr second.")
	AddConVar("sf_moonscale",6,"The scale of the moon.")
	AddConVar("sf_sv_material_replacment",1,"Enable material-replacment for weather effects.")
	AddConVar("sf_replacment_dirtgrassonly",0,"Only replace dirt and grass. (Useful on crazy maps)")
	AddConVar("sf_disablefog",0,"Disable SF editing the fog.")
	AddConVar("sf_disableweatherdebuffs",game.IsDedicated() and 1 or 0,"Disable weather debuffs/damage/impact.")
	AddConVar("sf_disable_windpush",game.IsDedicated() and 1 or 0,"Disable wind-push on props (Careful on servers).")
	AddConVar("sf_disablelightningbolts",0,"Disable lightning strikes.")
	AddConVar("sf_disable_autoweather",0,"Disable the automatic weather-generator.")
	AddConVar("sf_disable_mapsupport",0,"Disable the entity-support for maps.")
	AddConVar("sf_disable_autoweather_cold",0,"Disable autoweather creating snow.")
	AddConVar("sf_sunmoon_yaw",270,"The sun/moon yaw.")
	AddConVar("sf_debugcompatibility",0,"Enable SF compatability-debugger.")
	AddConVar("sf_disableskybox",0,"Disable the SF-skybox.")
	AddConVar("sf_enable_ekstra_lightsupport",0,"Enable ekstra lightsupport (engine.LightStyle)")
	AddConVar("sf_start_time","","Start the server at a specific time.")
	AddConVar("sf_disable_mapbloom",0,"Disable SF editing light-bloom.")
	AddConVar("sf_disblemapbrowser",game.IsDedicated() and 1 or 0,"Disable people changing the map with SF-browser.")

if SERVER then
	if StormFox.WorkShopVersion then
		resource.AddWorkshop("1132466603")
	else
		file.CreateDir("stormfox")
		file.CreateDir("stormfox/maps")

	-- Add addon content
		local i = 0
		local function AddDir(dir,dirlen)
			if not dirlen then dirlen = dir:len() end
			local files, folders = file.Find(dir .. "/*", "GAME")
			for _, fdir in ipairs(folders) do
				if fdir != ".svn" then
					AddDir(dir .. "/" .. fdir)
				end
			end
			for k, v in ipairs(files) do
				local fil = dir .. "/" .. v --:sub(dirlen + 2)
				resource.AddFile(fil)
		--		if string.find(fil,"vmt") or string.find(fil,"png") then
		--			print('"' .. string.sub(fil,11) .. '",')
		--		end
				i = i + 1
			end
		end
		AddDir("materials/stormfox")
		AddDir("sound/stormfox")

		MsgN("[StormFox] Added " .. i .. " content files")
	end
else
	CreateClientConVar("sf_exspensive","0",true,false,"[0-7+] Enable exspensive weather calculations.")
	CreateClientConVar("sf_material_replacment","1",true,false,"Enable material replacment for weather effects.")
	CreateClientConVar("sf_allow_rainsound","1",true,false,"Enable rain-sounds.")
	CreateClientConVar("sf_allow_windsound","1",true,false,"Enable wind-sounds.")
	CreateClientConVar("sf_allow_dynamiclights","1",true,false,"Enable lamp-lights from SF.")
	CreateClientConVar("sf_allow_sunbeams","1",true,false,"Enable sunbeams.")
	CreateClientConVar("sf_allow_dynamicshadow","0",true,false,"Enable dynamic light/shadows.")
	CreateClientConVar("sf_dynamiclightamount","1",true,false,"Controls the dynamic-light amount.")
	CreateClientConVar("sf_redownloadlightmaps","1",true,false,"Lighterrors and light_environment fix (Can lagspike)")
	CreateClientConVar("sf_allow_raindrops","1",true,false,"Enables raindrops on the screen")
	CreateClientConVar("sf_renderscreenspace_effects","1",true,false,"Enables RenderScreenspaceEffects")
end

-- Launch Stormfox
	-- Adds and runs files
	local function HandleFile(str)
		local path = str
		if string.find(str,"/") then
			path = string.GetFileFromFilename(str)
		end
		local _type = string.sub(path,0,3)
		if SERVER then
			if _type == "cl_" or _type == "sh_" then
				AddCSLuaFile(str)
			end
			if _type != "cl_" then
				--print("Running: " .. path)
				return include(str)
			end
		elseif _type != "sv_" then
			--print("Running: " .. path)
			return include(str)
		end
	end

for _,fil in ipairs(file.Find("stormfox/framework/*.lua","LUA")) do
	HandleFile("stormfox/framework/" .. fil)
end

for _,fil in ipairs(file.Find("stormfox/functions/*.lua","LUA")) do
	HandleFile("stormfox/functions/" .. fil)
end

HandleFile("stormfox/" .. "sh_debugcompatibility.lua")
HandleFile("stormfox/" .. "sh_weathertype_meta.lua")
HandleFile("stormfox/" .. "sh_weather_controller.lua")

if SERVER then
	HandleFile("stormfox/" .. "sv_map_lights.lua")
	HandleFile("stormfox/" .. "sv_weather_generator.lua")
end
for _,fil in ipairs(file.Find("stormfox/weather_types/*.lua","LUA")) do
	if SERVER then
		AddCSLuaFile("stormfox/weather_types/" .. fil)
	end
	include("stormfox/weather_types/" .. fil)
end
HandleFile("stormfox/" .. "sh_options.lua")
HandleFile("stormfox/" .. "cl_wizard.lua")
HandleFile("stormfox/" .. "cl_mapbrowser.lua")
hook.Call("StormFox - PostInit")

local t1 = util.JSONToTable(file.Read("stormfox/maps/" .. game.GetMap() .. ".txt","DATA"))
local t2 = util.JSONToTable(file.Read("stormfox/maps/" .. game.GetMap() .. " - Kopi.txt","DATA"))
for _type,tab in pairs(t2) do
	for matstr,str in pairs(tab) do
		if not t1[_type][matstr] then
			print("Not added",matstr)
		end
	end
end