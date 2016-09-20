--BlueUpdater - Client Script (CORE)
--Author: gnmmarechal
--Runs on Lua Player Plus 3DS

-- This script fetches the latest updater script and runs it. If the server-side script has a higher rel number, the CIA will also be updated.
clientrel = 1
bootstrapver = "1.0.3"

if not Network.isWifiEnabled() then --Checks for Wi-Fi
	error("Failed to connect to the network.")
end

-- Set server script URL
stableserverscripturl = "http://gs2012.xyz/3ds/BlueUpdater/index-server.lua"
nightlyserverscripturl = "http://gs2012.xyz/3ds/BlueUpdater/cure-nightly.lua"

--Set server CIA type (BGM/NOBGM)
if System.doesFileExist("romfs:/bgm.wav") then
	CIAupdatetype = "BGM"
else
	CIAupdatetype = "NOBGM"
end

-- Create directories
System.createDirectory("/BlueUpdater")
System.createDirectory("/BlueUpdater/settings")
System.createDirectory("/BlueUpdater/resources")


-- Check if user is in devmode or no (to either use index-server.lua or cure-nightly.lua)
if System.doesFileExist("/BlueUpdater/settings/devmode") then
	serverscripturl = nightlyserverscripturl
	devmode = 1
else
	serverscripturl = stableserverscripturl
	devmode = 0
end
-- Download server script
if System.doesFileExist("/BlueUpdater/cure.lua") then
	System.deleteFile("/BlueUpdater/cure.lua")
end
Network.downloadFile(serverscripturl, "/BlueUpdater/cure.lua")

--CIA/3DSX Check
local iscia = 0
if System.checkBuild() == 2 then
	iscia = 0
else
	iscia = 1
end

-- Run server script
dofile("/BlueUpdater/cure.lua")
System.exit()
