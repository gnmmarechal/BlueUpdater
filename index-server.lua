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

if System.doesFileExist("/BlueUpdater/settings/keepconfig") then
	configkeep = 1
else
	configkeep = 0
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
baseserver = "http://gs2012.xyz/3ds/BlueUpdater"

local url =
{
	hourly = "http://astronautlevel2.github.io/Luma3DS/latest.zip",
	stable = "http://astronautlevel2.github.io/Luma3DS/release.zip",
	remver = Network.requestString("http://astronautlevel2.github.io/Luma3DS/lastVer"),
	remcommit = Network.requestString("http://astronautlevel2.github.io/Luma3DS/lastCommit")
}

-- More vars
localzip = "/BlueUpdater/resources/cfw.zip"

-- CFG Paths
armcfgpath = "/BlueUpdater/settings/a9lh.cfg"
mhxcfgpath = "/BlueUpdater/settings/mhx.cfg"

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

-- Prechecks
function readconfig(cfgpath, cfw)
	-- Checks for a config file
	if System.doesFileExist(cfgpath) then
		configstream = io.open(cfgpath, FREAD)
		temppayloadpath = io.read(configstream,0,io.size(configstream))
		io.close(configstream)
		if not System.doesFileExist(temppayloadpath) then
			-- File doesn't exist
			System.deleteFile(cfgpath)
			readconfig(cfgpath, cfw)
		end
		if cfw == "corbenik" then
			corbenikarmpayloadpath = temppayloadpath
		else
			skeitharmpayloadpath = temppayloadpath
		end
	else
		temppayloadpath = "/arm9loaderhax.bin"
		if System.doesFileExist("/arm9loaderhax_si.bin") then
			temppayloadpath = "/arm9loaderhax_si.bin"
		end
		if cfw == "corbenik" then
			corbenikarmpayloadpath = temppayloadpath
		else
			skeitharmpayloadpath = temppayloadpath
		end
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
	readconfig(corbenikcfgpath, "corbenik")
	readconfig(skeithcfgpath, "skeith")
end

function freshinstall(cfwpath) -- Installs Corbenik/Skeith from scratch
	headflip = 1
	head()
	-- Lazy fixes
	Screen.debugPrint(0,180,"B) Quit", black, TOP_SCREEN)
	if showskeith == 0 then
		Screen.debugPrint(0,160,"X) Install nightly - Skeith CFW", black, TOP_SCREEN)
	else
		Screen.debugPrint(0,160,"X) Update nightly - Skeith CFW", black, TOP_SCREEN)		
	end	
	-- Installer
	if cfwpath == "/corbenik" then
		cfwname = "Corbenik"
		cfwurl = corbenikurl
		armpayloadpath = corbenikarmpayloadpath
		dl =
		{
			native = old.native,
			nativecetk = old.nativecetk,
			twl = old.twl,
			twlcetk = old.twlcetk,
			agb = old.agb,
			agbcetk = old.agbcetk
		}
	elseif cfwpath == "/skeith" then
		cfwname = "Skeith"
		cfwurl = skeithurl
		armpayloadpath = skeitharmpayloadpath
		dl =
		{
			native = new.native,
			nativecetk = new.nativecetk,
			twl = new.twl,
			twlcetk = new.twlcetk,
			agb = new.agb,
			agbcetk = new.agbcetk
		}
	end
	paths =
	{
		native = cfwpath.."/lib/firmware/native",
		nativecetk = cfwpath.."/share/keys/native.cetk",
		twl = cfwpath.."/lib/firmware/twl",
		twlcetk = cfwpath.."/share/keys/twl.cetk",
		agb = cfwpath.."/lib/firmware/agb",
		agbcetk = cfwpath.."/share/keys/agb.cetk"
	}	
	
	-- Download CFW ZIP
	debugWrite(0,60,"Downloading "..cfwname.." CFW ZIP...", white, TOP_SCREEN)
	if updated == 0 then
		h,m,s = System.getTime()
		day_value,day,month,year = System.getDate()	
		Network.downloadFile(cfwurl, localzip)
	end
	
	-- Extract CFW to its directory
	debugWrite(0,80,"Extracting CFW files...", white, TOP_SCREEN)
	if updated == 0 then
		-- Renames arm9loaderhax payload to something else to prevent it from being overwritten by the ZIP extraction
		System.renameFile("/arm9loaderhax.bin", "/arm9loaderhax".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin")
		System.renameFile("/arm9loaderhax_si.bin", "/arm9loaderhax_si".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin")
		-- Extracts the CFW's ZIP package
		System.extractZIP(localzip, "/")
		-- Deletes the arm9loaderhax payload that was extracted.
		System.deleteFile("/arm9loaderhax.bin")
		-- Extracts the payload to its path (according to config or default path)
		System.extractFromZIP(localzip,"arm9loaderhax.bin",armpayloadpath)
		-- If default path wasn't one of the standard A9LH paths, rename the previously backed up files to standard.
		if not System.doesFileExist("/arm9loaderhax.bin") and not System.doesFileExist("/arm9loaderhax_si.bin") and not System.doesFileExist("/homebrew/3ds/boot.bin") then
			System.renameFile("/arm9loaderhax_si".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin", "/arm9loaderhax_si.bin")
			System.renameFile("/arm9loaderhax".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin", "/arm9loaderhax.bin")
		end
		-- Post-installation cleanup
		System.deleteFile(localzip)
		-- Clean files that were in the package and are not needed.
		if System.doesFileExist("/README.md") then
			System.deleteFile("/README.md")
		end
		if System.doesFileExist("/LICENSE.txt") then
			System.deleteFile("/LICENSE.txt")
		end
		if System.doesFileExist("/generate_localeemu.sh") then
			System.deleteFile("/generate_localeemu.sh")
		end
		if System.doesFileExist("/n3ds_firm.sh") then
			System.deleteFile("/n3ds_firm.sh")
		end
		if System.doesFileExist("/o3ds_firm.sh") then
			System.deleteFile("/o3ds_firm.sh")
		end
	end	
	-- Download FIRM, CETKs, etc.
	debugWrite(0,100,"Downloading required files...", white, TOP_SCREEN)	
	if updated == 0 then
		Network.downloadFile(dl.native, paths.native)
		Network.downloadFile(dl.nativecetk, paths.nativecetk)
		Network.downloadFile(dl.twl, paths.twl)
		Network.downloadFile(dl.twlcetk, paths.twlcetk)
		Network.downloadFile(dl.agb, paths.agb)
		Network.downloadFile(dl.agbcetk, paths.agbcetk)		
	end	
	debugWrite(0,120,"Installed. Press A to reboot or B to quit!", green, TOP_SCREEN)
	updated = 1	
end
function installcfw(cfwpath) -- used as "installcfw("/corbenik", 1)", for example, for a Corbenik  installation that keeps old config
	headflip = 1
	head()
	-- Lazy fixes
	Screen.debugPrint(0,180,"B) Quit", black, TOP_SCREEN)
	if showskeith == 0 then
		Screen.debugPrint(0,160,"X) Install nightly - Skeith CFW", black, TOP_SCREEN)
	else
		Screen.debugPrint(0,160,"X) Update nightly - Skeith CFW", black, TOP_SCREEN)		
	end
	-- Installer
	if cfwpath == "/corbenik" then
		cfwname = "Corbenik"
		cfwurl = corbenikurl
		armpayloadpath = corbenikarmpayloadpath
	elseif cfwpath == "/skeith" then
		cfwname = "Skeith"
		cfwurl = skeithurl
		armpayloadpath = skeitharmpayloadpath
	end
	-- Check for configkeep variable
	if configkeep == 1 then
		keepconfig = 1
		else
		keepconfig = 0
	end
	
	debugWrite(0,60,"Downloading "..cfwname.." CFW ZIP...", white, TOP_SCREEN)
	if updated == 0 then -- Download the file
		Network.downloadFile(cfwurl, localzip)
	end
	debugWrite(0,80,"Backing up old installation...", red, TOP_SCREEN)
	if updated == 0 then -- Back up, and set the back up filename (same filename scheme as the original updater, save for the arm9loaderhax payload)
		h,m,s = System.getTime()
		day_value,day,month,year = System.getDate()
		oldcfwpath = cfwpath.."-BACKUP-"..h..m..s..day_value..day..month..year
		oldarmpayloadpath = armpayloadpath.."-BACKUP-"..h..m..s..day_value..day..month..year..".bak"
		System.renameDirectory(cfwpath, oldcfwpath)
		System.renameFile(armpayloadpath, oldarmpayloadpath)
	end
	debugWrite(0,100,"Installing CFW update...", white, TOP_SCREEN)
	if updated == 0 then
		-- Renames arm9loaderhax payload to something else to prevent it from being overwritten by the ZIP extraction
		System.renameFile("/arm9loaderhax.bin", "/arm9loaderhax".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin")
		System.renameFile("/arm9loaderhax_si.bin", "/arm9loaderhax_si".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin")
		-- Extracts the CFW's ZIP package
		System.extractZIP(localzip, "/")
		-- Deletes the arm9loaderhax payload that was extracted.
		System.deleteFile("/arm9loaderhax.bin")
		-- Extracts the payload to its path (according to config or default path)
		System.extractFromZIP(localzip,"arm9loaderhax.bin",armpayloadpath)
		-- If default path wasn't one of the standard A9LH paths, rename the previously backed up files to standard.
		if not System.doesFileExist("/arm9loaderhax.bin") and not System.doesFileExist("/arm9loaderhax_si.bin") and not System.doesFileExist("/homebrew/3ds/boot.bin") then
			System.renameFile("/arm9loaderhax_si".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin", "/arm9loaderhax_si.bin")
			System.renameFile("/arm9loaderhax".."-BACKUP-"..h..m..s..day_value..day..month..year..".bin", "/arm9loaderhax.bin")
		end
		-- Deletes empty directories that were in the package
		System.deleteDirectory(cfwpath.."/lib/firmware")
		System.deleteDirectory(cfwpath.."/share/keys")
		System.deleteDirectory(cfwpath.."/share/locale/emu")
		-- Moves required files from old installation to new
		System.renameDirectory(oldcfwpath.."/lib/firmware",cfwpath.."/lib/firmware")
		System.renameDirectory(oldcfwpath.."/share/keys",cfwpath.."/share/keys")
		-- Moves locale files if they exist
		System.createDirectory(oldcfwpath.."/share/locale/emu")
		System.renameDirectory(oldcfwpath.."/share/locale/emu",cfwpath.."/share/locale/emu")
		-- Moves splash screens (top.bin and bottom.bin) to new directory
		if System.doesFileExist(oldcfwpath.."/share/top.bin") then
			System.renameFile(oldcfwpath.."/share/top.bin", cfwpath.."/share/top.bin")
		end
		if System.doesFileExist(oldcfwpath.."/share/bottom.bin") then
			System.renameFile(oldcfwpath.."/share/bottom.bin", cfwpath.."/share/bottom.bin")
		end
		-- Remove the extra copy of Corbenik if it exists
		if System.doesFileExist(cfwpath.."/boot/Corbenik") then
			System.deleteFile(cfwpath.."/boot/Corbenik")
		end
		-- Move chainloading payloads to /boot
		System.deleteDirectory(cfwpath.."/boot")
		System.createDirectory(oldcfwpath.."/boot")
		System.renameDirectory(oldcfwpath.."/boot",cfwpath.."/boot")
		-- Keep config if keepconfig == 1
		if keepconfig == 1 then
			-- Deletes the empty /etc directory
			System.deleteDirectory(cfwpath.."/etc")
			-- Moves cache and config to installation directory
			System.renameDirectory(oldcfwpath.."/etc",cfwpath.."/etc")
			System.renameDirectory(oldcfwpath.."/var/cache",cfwpath.."/var/cache")
		end
		-- Post-installation cleanup
		System.deleteFile(localzip)
		-- Clean files that were in the package and are not needed.
		if System.doesFileExist("/README.md") then
			System.deleteFile("/README.md")
		end
		if System.doesFileExist("/LICENSE.txt") then
			System.deleteFile("/LICENSE.txt")
		end
		if System.doesFileExist("/generate_localeemu.sh") then
			System.deleteFile("/generate_localeemu.sh")
		end
		if System.doesFileExist("/n3ds_firm.sh") then
			System.deleteFile("/n3ds_firm.sh")
		end
		if System.doesFileExist("/o3ds_firm.sh") then
			System.deleteFile("/o3ds_firm.sh")
		end
	end
	debugWrite(0,120,"Updated. Press A to reboot or B to quit!", green, TOP_SCREEN)
	updated = 1	
end

function isdirtyupdate() -- Checks whether to keep config or not and sets the var for it.
	if configkeep == 1 then
		configkept = "Yes"
	else
		configkept = "No"
	end
	if Controls.check(pad, KEY_R) and not Controls.check(oldpad, KEY_R) then
		if configkeep == 1 then
			configkeep = 0
			keepconfig = 0
			-- Delete config setting for this option
			System.deleteFile("/corbenik-updater-re/settings/keepconfig")
		else
			configkeep = 1
			keepconfig = 1
			-- Create config option for this option to be saved upon exit and restart
			confsettingstream = io.open("/corbenik-updater-re/settings/keepconfig",FCREATE)
			io.write(confsettingstream,0,"Keep Config", 11)
			io.close(confsettingstream)
		end
	end
end

function bgmtogglecheck() -- Checks for KEY_L and toggles BGM usage (requires restart of the updater to take effect)
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
-- Actual UI screens

function head() -- Head of all screens
	if headflip == 1 then
		debugWrite(0,0,"Corbenik CFW Updater: RE v."..version, white, TOP_SCREEN)
		debugWrite(0,20,"==============================", red, TOP_SCREEN)	
	end
	Screen.debugPrint(0,0,"Corbenik CFW Updater: RE v."..version, white, TOP_SCREEN)
	Screen.debugPrint(0,20,"==============================", red, TOP_SCREEN)	
end

function bottomscreen() -- Bottom Screen
	if headflip == 1 then
		debugWrite(0,0, "Latest Corbenik CFW: v"..corbenikver, green, BOTTOM_SCREEN)
		debugWrite(0,20, "Latest Skeith CFW: "..skeithver, green, BOTTOM_SCREEN)
		debugWrite(0,40, "==============================", red, BOTTOM_SCREEN)
		debugWrite(0,60, "CURE Version: "..version, white, BOTTOM_SCREEN)
		debugWrite(0,80, "CORE Version: "..bootstrapver, white, BOTTOM_SCREEN)
		debugWrite(0,100, "==============================", red, BOTTOM_SCREEN)
		debugWrite(0,120, "Author: gnmmarechal", white, BOTTOM_SCREEN)
		debugWrite(0,140, "Special Thanks:", white, BOTTOM_SCREEN)
		debugWrite(0,160, "Crystal the Glaceon (Tester)", white, BOTTOM_SCREEN)
		debugWrite(0,180, "chaoskagami (CFW Developer)", white, BOTTOM_SCREEN)
		debugWrite(0,200, "Rinnegatamante (LPP-3DS/Help)", white, BOTTOM_SCREEN)
	end
	Screen.debugPrint(0,0, "Latest Corbenik CFW: v"..corbenikver, green, BOTTOM_SCREEN)
	Screen.debugPrint(0,20, "Latest Skeith CFW: "..skeithver, green, BOTTOM_SCREEN)
	Screen.debugPrint(0,40, "==============================", red, BOTTOM_SCREEN)
	Screen.debugPrint(0,60, "CURE Version: "..version, white, BOTTOM_SCREEN)
	Screen.debugPrint(0,80, "CORE Version: "..bootstrapver, white, BOTTOM_SCREEN)	
	Screen.debugPrint(0,100, "==============================", red, BOTTOM_SCREEN)	
	Screen.debugPrint(0,120, "Author: gnmmarechal", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,140, "Special Thanks:", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,160, "Crystal the Glaceon (Tester)", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,180, "chaoskagami (CFW Developer)", white, BOTTOM_SCREEN)
	Screen.debugPrint(0,200, "Rinnegatamante (LPP-3DS/Help)", white, BOTTOM_SCREEN)	
end

function firstscreen() -- scr == 1 | First UI screen, main menu
	head()
	Screen.debugPrint(0,40,"Welcome to Corbenik CFW Updater: RE!", white, TOP_SCREEN)
	Screen.debugPrint(0,100,"Please select an option:", white, TOP_SCREEN)
	Screen.debugPrint(0,120,"Keep Config (Press R): "..configkept, white, TOP_SCREEN)
	if showcorbenik == 1 then
		Screen.debugPrint(0, 140,"A) Update stable - Corbenik CFW", white, TOP_SCREEN)
		inputscr(2, KEY_A)
	else
		Screen.debugPrint(0, 140,"A) Install stable - Corbenik CFW", white, TOP_SCREEN)
		inputscr(4, KEY_A)
	end
	if showskeith == 1 then
		Screen.debugPrint(0,160,"X) Update nightly - Skeith CFW", white, TOP_SCREEN)
		inputscr(3, KEY_X)
	else
		Screen.debugPrint(0, 160,"X) Install nightly - Skeith CFW", white, TOP_SCREEN)
		inputscr(5, KEY_X)		
	end
	Screen.debugPrint(0,180,"B) Quit", white, TOP_SCREEN)
	inputscr(-1, KEY_B)
end

function installer(cfwpath) -- scr == 2/3 | Installation UI screen
	head()
	debugWrite(0, 40, "Started installation of CFW...", white, TOP_SCREEN)
	installcfw(cfwpath)
	inputscr(-1, KEY_B) -- Checks for exit
	inputscr(-2, KEY_A) -- Checks for reboot
end

function newinstaller(cfwpath) -- scr = 4/5 | Installation UI Screen (FRESH)
	head()
	debugWrite(0, 40, "Started fresh installation of CFW...", white, TOP_SCREEN)
	freshinstall(cfwpath)
	inputscr(-1, KEY_B)
	inputscr(-2, KEY_A)
end	

-- Main Loop
precheck()
precleanup()

while true do
	clear()
	pad = Controls.read()
	bottomscreen() -- Display bottom screen info
	-- Checks for BGM toggle and dirty/clean update toggle
	isdirtyupdate()
	bgmtogglecheck()
	-- Actual UI screens and installer phases
	
	if scr == 3 then
		installer("/skeith")
	elseif scr == 2 then
		installer("/corbenik")
	elseif scr == 4 then
		newinstaller("/corbenik")
	elseif scr == 5 then
		newinstaller("/skeith")
	elseif scr == 1 then
		firstscreen()
	end
	
	flip()
end