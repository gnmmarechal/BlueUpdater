--BlueUpdater - Server Script (CURE)
--Author: gnmmarechal
--Runs on Lua Player Plus 3DS
serverrel = 1
version = "1.0.0"
if devmode == 1 then -- This will differentiate between stable and devscripts.
	version = version.."-D"
end
-- Handle Outdated CIA Notification
if serverrel > clientrel then
	error("New CORE CIA available. Please update.")
end
-- Settings checks
if System.doesFileExist("/BlueUpdater/settings/usebgm") then
	usebgm = 1
end


-- Checks
if usebgm == 1 then
	--Check for existence of DSP firm dump, if not, disable BGM.
	if not System.doesFileExist("/3ds/dspfirm.cdc") then
		usebgm = 0
	end
	--Check for existence of BGM, if none is found, disable BGM.
	if System.doesFileExist("/BlueUpdater/resources/bgm.wav") then
		bgmpath = "/BlueUpdater/resources/bgm.wav"
	elseif System.doesFileExist("/corbenik-updater-re/resources/bgm.wav") then
		bgmpath = "/corbenik-updater-re/resources/bgm.wav"
	elseif System.doesFileExist("romfs:/bgm.wav") then
		bgmpath = "romfs:/bgm.wav"
	else -- Disable BGM if no BGM is found
		usebgm = 0
	end
else
	usebgm = 0
end

-- Start BGM
if usebgm == 1 then
	Sound.init()
	bgm = Sound.openWav(bgmpath, false)
	Sound.play(bgm, LOOP)
end

-- Variables
updated = 0
scr = 1
oldpad = Controls.read()
MAX_RAM_ALLOCATION = 10485760

--Colours
white = Color.new(255,255,255)
green = Color.new(0,240,32)
red = Color.new(255,0,0)
yellow = Color.new(255,255,0)
black = Color.new(0,0,0)

-- File URLs
local baseserver = "http://gs2012.xyz/3ds/BlueUpdater"

local url =
{
	hourly = "http://astronautlevel2.github.io/Luma3DS/latest.zip",
	stable = "http://astronautlevel2.github.io/Luma3DS/release.zip",
	remver = Network.requestString("http://astronautlevel2.github.io/Luma3DS/lastVer"),
	remcommit = Network.requestString("http://astronautlevel2.github.io/Luma3DS/lastCommit")
}

-- More vars
local localzip = "/BlueUpdater/resources/cfw.zip"
local payload_path = "/arm9loaderhax.bin"

-- CFG Paths
local armcfgpath = "/BlueUpdater/settings/a9lh.cfg"
local mhxcfgpath = "/BlueUpdater/settings/mhx.cfg"
local isMenuhax = 0

--System functions
function fileCopy(input, output)
		inp = io.open(input,FREAD)
	if System.doesFileExist(output) then
		System.deleteFile(output)
	end
	out = io.open(output,FCREATE)
	size = io.size(inp)
	index = 0
	while (index+(MAX_RAM_ALLOCATION/2) < size) do
		io.write(out,index,io.read(inp,index,MAX_RAM_ALLOCATION/2),(MAX_RAM_ALLOCATION/2))
		index = index + (MAX_RAM_ALLOCATION/2)
	end
	if index < size then
		io.write(out,index,io.read(inp,index,size-index),(size-index))
	end
	io.close(inp)
	io.close(out)
end

function sleep(n)
  local timer = Timer.new()
  local t0 = Timer.getTime(timer)
  while Timer.getTime(timer) - t0 <= n do end
end

function readConfig(fileName)
    if (isMenuhax) then
        payload_path = "/Luma3DS.dat"
        backup_path = payload_path..".bak"
        return
    end
    if (System.doesFileExist(fileName)) then
        local file = io.open(fileName, FREAD)
        payload_path = io.read(file, 0, io.size(file))
        payload_path = string.gsub(payload_path, "\n", "")
        payload_path = string.gsub(payload_path, "\r", "")
        backup_path = payload_path..".bak"
    elseif (not System.doesFileExist(fileName) and not isMenuhax) then
		if System.doesFileExist("/arm9loaderhax_si.bin") and (not System.doesFileExist("/arm9loaderhax.bin")) then
			payload_path = "/arm9loaderhax_si.bin"
		else
			payload_path = "/arm9loaderhax.bin"
		end
        backup_path = payload_path..".bak"
        return
    end
end

function clear()

	Screen.refresh()
	Screen.clear(TOP_SCREEN)
	Screen.clear(BOTTOM_SCREEN)
end 

function flip()
	Screen.flip()
	Screen.waitVblankStart()
	oldpad = pad
end

function waitloop()
	loop = 0
end

function quit()
	if usebgm == 0 then
	
	else
		Sound.close(bgm)
		Sound.term()
	end
	System.exit()
end

function debugWrite(x,y,text,color,display)
	if updated == 1 then
		Screen.debugPrint(x,y,text,color,display)
	else
		i = 0
	
		while i < 2 do
			Screen.refresh()
			Screen.debugPrint(x,y,text,color,display)
			Screen.waitVblankStart()
			Screen.flip()
			i = i + 1
		
		end
	end
end

-- Input, UI functions

function inputscr(newscr, inputkey)
	if Controls.check(pad,inputkey) and not Controls.check(oldpad,inputkey) then
		if newscr == -1 then
			quit()
		end
		if newscr == -2 then
			if usebgm == 0 then
			else
				Sound.close(bgm)
				Sound.term()
			end
			System.reboot()
		end
		Screen.clear(TOP_SCREEN)
		scr = newscr
	end	
end

-- Important cleanup function
function precleanup()
	if System.doesFileExist(localzip) then
		System.deleteFile(localzip)
	end
end

function precheck()
	--Check model, if N3DS, set clock to 804MHz
	if System.getModel() == 2 or System.getModel() == 4 then
		System.setCpuSpeed(NEW_3DS_CLOCK)
		newconsole = 1
	else
		newconsole = 0
	end
	readConfig(armcfgpath)
end

function installcfw(dlurl)
	headflip = 1
	head()
	debugWrite(0,60, "Downloading CFW ZIP...", white, TOP_SCREEN)
	if updated == 0 then
        Network.downloadFile(dlurl, localzip)	
	end
	debugWrite(0,80, "Backing up payload...", red, TOP_SCREEN)
	if updated == 0 then
        if (System.doesFileExist(backup_path)) then
            System.deleteFile(backup_path)
        end
        if (System.doesFileExist(payload_path)) then
            System.renameFile(payload_path, backup_path)
        end
	end	
	debugWrite(0,100, "Installing Luma3DS...", white, TOP_SCREEN)
	if updated == 0 then
		if isMenuhax == 0 then
			System.extractFromZIP(localzip, "out/arm9loaderhax.bin", payload_path)
			System.deleteFile(localzip)
		else
			System.extractFromZIP(localzip, "out/Luma3DS.dat", "/Luma3DS.dat")
			if System.doesFileExist("/arm9loaderhax.bin") then
				System.deleteFile("/arm9loaderhax.bin")
			end
			System.extractFromZIP(localzip, "out/arm9loaderhax.bin", "/arm9loaderhax.bin")
			System.deleteFile(localzip)
		end	
	end
	if isMenuhax == 0 then
		debugWrite(0, 120, "Changing path for reboot patch...", red, TOP_SCREEN)
		if updated == 0 then
			path_changer()
		end
	end
	debugWrite(0,140,"Updated. Press A to reboot or B to quit!", green, TOP_SCREEN)
	updated = 1	
end

function bgmtogglecheck() -- Checks for KEY_SELECT and toggles BGM usage (requires restart of the updater to take effect)
	if Controls.check(pad, KEY_SELECT) and not Controls.check(oldpad, KEY_SELECT) then
		if System.doesFileExist("/corbenik-updater-re/settings/usebgm") then
			System.deleteFile("/corbenik-updater-re/settings/usebgm")
		else
			bgmsettingstream = io.open("/corbenik-updater-re/settings/usebgm",FCREATE)
			io.write(bgmsettingstream,0,"Use BGM", 7)
			io.close(bgmsettingstream)
		end
	end
end


function checkmenuhaxmode() -- Checks whether to keep config or not and sets the var for it.

	if isMenuhax == 1 then

		modename = "MenuHax"

	else

		modename = "Arm9LoaderHax"

	end

	if Controls.check(pad, KEY_R) and not Controls.check(oldpad, KEY_R) then

		if isMenuhax == 1 then

			isMenuhax = 0

			-- Delete config setting for this option

			System.deleteFile("/BlueUpdater/settings/menuhax")

		else
			
			isMenuhax = 1

			-- Create config option for this option to be saved upon exit and restart

			confsettingstream = io.open("/BlueUpdater/settings/menuhax",FCREATE)

			io.write(confsettingstream,0,"Keep Config", 11)

			io.close(confsettingstream)

		end

	end

end


-- Actual UI screens

function head() -- Head of all screens
	if headflip == 1 then
		debugWrite(0,0,"BlueUpdater v."..version, white, TOP_SCREEN)
		debugWrite(0,20,"==============================", red, TOP_SCREEN)	
	end
	Screen.debugPrint(0,0,"BlueUpdater v."..version, white, TOP_SCREEN)
	Screen.debugPrint(0,20,"==============================", red, TOP_SCREEN)	
end

function bottomscreen() -- Bottom Screen
	if headflip == 1 then
		debugWrite(0,0, "Latest stable: v"..stablever, green, BOTTOM_SCREEN)
		debugWrite(0,20, "Latest hourly: "..nightlyver, green, BOTTOM_SCREEN)
		debugWrite(0,40, "==============================", red, BOTTOM_SCREEN)
		debugWrite(0,60, "CURE Version: "..version, white, BOTTOM_SCREEN)
		debugWrite(0,80, "CORE Version: "..bootstrapver, white, BOTTOM_SCREEN)
		debugWrite(0,100, "==============================", red, BOTTOM_SCREEN)
		debugWrite(0,120, "Author: gnmmarechal", white, BOTTOM_SCREEN)
		debugWrite(0,140, "Special Thanks:", white, BOTTOM_SCREEN)
		debugWrite(0,160, "Crystal the Glaceon (Tester)", white, BOTTOM_SCREEN)
		debugWrite(0,180, "astronautlevel (StarUpdater)", white, BOTTOM_SCREEN)
		debugWrite(0,200, "Rinnegatamante (LPP-3DS/Help)", white, BOTTOM_SCREEN)
	end
	Screen.debugPrint(0,0, "Latest stable: v"..stablever, green, BOTTOM_SCREEN)
	Screen.debugPrint(0,20, "Latest hourly: "..nightlyver, green, BOTTOM_SCREEN)
	Screen.debugPrint(0,40, "==============================", red, BOTTOM_SCREEN)
	Screen.debugPrint(0,60, "CURE Version: "..version, white, BOTTOM_SCREEN)
	Screen.debugPrint(0,80, "CORE Version: "..bootstrapver, white, BOTTOM_SCREEN)	
	Screen.debugPrint(0,100, "==============================", red, BOTTOM_SCREEN)	
	Screen.debugPrint(0,120, "Author: gnmmarechal", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,140, "Special Thanks:", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,160, "Crystal the Glaceon (Tester)", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,180, "astronautlevel (StarUpdater)", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,200, "Rinnegatamante (LPP-3DS/Help)", white, BOTTOM_SCREEN)	
end

function firstscreen() -- scr == 1 | First UI screen, main menu
	head()
	Screen.debugPrint(0,40,"Welcome to BlueUpdater!", white, TOP_SCREEN)
	Screen.debugPrint(0,100,"Please select an option:", white, TOP_SCREEN)
	Screen.debugPrint(0,120,"Mode (Press R): "..modename, white, TOP_SCREEN)
	Screen.debugPrint(0, 140,"A) Update stable Luma3DS", white, TOP_SCREEN)
	inputscr(2, KEY_A)

	Screen.debugPrint(0, 160,"X) Update hourly Luma3DS", white, TOP_SCREEN)
	inputscr(3, KEY_X)
	Screen.debugPrint(0,180,"B) Quit", white, TOP_SCREEN)
	inputscr(-1, KEY_B)
end

function installer(dlurl) -- scr == 2/3 | Installation UI screen
	head()
	debugWrite(0, 40, "Started installation of CFW...", white, TOP_SCREEN)
	installcfw(dlurl)
	inputscr(-1, KEY_B) -- Checks for exit
	inputscr(-2, KEY_A) -- Checks for reboot
end

-- Main Loop
precheck()
precleanup()

while true do
	clear()
	pad = Controls.read()
	bottomscreen() -- Display bottom screen info
	checkmenuhaxmode()
	bgmtogglecheck()
	-- Actual UI screens and installer phases
	
	if scr == 3 then
		installer(url.hourly)
	elseif scr == 2 then
		installer(url.stable)
	elseif scr == 1 then
		firstscreen()
	end
	
	flip()
end
