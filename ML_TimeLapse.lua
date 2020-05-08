-- Magic Lantern TimeLapse
Version = "1.0.0"
-- Exécution d'un cycle de photos pour réaliser un time lapse avec la gestion du passage du jour à la nuit.  
-- Qualifié avec un Canon 6D.  
-- Le programme ML_TimeLapse.lua va réaliser une série de photos avec un cycle précis.  
-- Il est exécuté par l'application Magic Lantern. Les informations sur Magic Lantern sont données dans le chapitre suivant.
--
-- Attention ! il faut activer le module lua  "Lua scripting" dans le menu Modules de MagicLantern
-- et copier ce script dans le répertoire M/SCRIPTS de la carte SD

-- load module keys
require("keys")
-- Load module logger
require ("logger")

-- Activation du mode log
LogToFile = 1
LoggingFile = nil

-- Mode test
-- Le mode test ne déclenche pas dans ce cas il faut que la valeur soit 1
-- Il est possible de configurer le TestMode dans la ligne de config du script de schedule
TestMode = 0

-- Log to stdout and optionally to a file
function log(s, ...)
	local str = string.format (s, ...)
	str = str .. "\n"
	if (LogToFile == 0 or LoggingFile == nil)
	then
		io.write (str)
	else
		LoggingFile:write (str)
	end
	return
end

-- Open log file
function log_start()
	if (LogToFile ~= 0)
	then
		local cur_time = dryos.date
		local filename = string.format("mltl.log")
		print (string.format ("Open log file %s", filename))
		LoggingFile = logger (filename)
	else
		print (string.format ("Logging not configured"))
	end
end

-- Close log file
function log_stop()
	if (LogToFile ~= 0)
	then
		print (string.format ("Close log file"))
		LoggingFile:close ()
	end
end

-- Get the current time (in seconds) from the camera's clock.
function get_cur_secs()
	local cur_time = dryos.date
	local cur_secs = (cur_time.hour * 3600 + cur_time.min * 60 + cur_time.sec)
	return cur_secs
end

-- Take a time variable expressed in seconds (which is what all times are stored as) and convert it back to HH:MM:SS
function pretty_time(time_secs)
	local text_time = ""
	local hrs = 0
	local mins = 0
	local secs = 0
	hrs =  math.floor(time_secs / 3600)
    mins = math.floor((time_secs - (hrs * 3600)) / 60)
	secs = (time_secs - (hrs*3600) - (mins * 60))
	text_time = string.format("%02d:%02d:%02d", hrs, mins, secs)
	return text_time
end

-- Take a time variable expressed in seconds (which is what all times are stored as) and convert it back to tab
function time_tab(time_secs)
	local timeTab = {}
	timeTab[1] = math.floor(time_secs / 3600)
    timeTab[2] = math.floor((time_secs - (timeTab[1] * 3600)) / 60)
	timeTab[3] = (time_secs - (timeTab[1]*3600) - (timeTab[2] * 60))
	return timeTab
end

-- Take a time expressed in hrs, min, sec and convert it to seconds
function convert_second(hrs, mins, secs)
    local seconds = (hrs * 3600 + mins * 60 + secs)
    return seconds
end

-- Take a shutter speed expressed in (fractional) seconds and convert it to 1/x.
function pretty_shutter(shutter_speed)
	local text_time = ""
	if (shutter_speed >= 1.0)
	then
		text_time = tostring (shutter_speed)
	else
		text_time = string.format ("1/%s", tostring (1/shutter_speed))
	end
	return text_time
end

function drow_box(title,value)
	--local rows = 1
	--local cols = 3
    local font = FONT.LARGE              --Type de fonte
    local border = COLOR.gray(75)
    local background = COLOR.gray(5)
    local foreground = COLOR.WHITE
    local highlight = COLOR.BLUE
    local error_forground = COLOR.RED
    local pad = 20
    --local cell_size = pad * 2 + font.height
    local height = pad * 2 + font.height
    local width = font:width(title..value) + (pad * 2)
    local left = display.width // 2 - width // 2
	local top = display.height // 2 - height // 2
	local error = false
	
	display.rect(left-4,top-4,width+8,height+8,border,border)	-- contour
	display.rect(left,top,width,height,border,background)	-- rectangle de saisie
	local fg = foreground
    if error then fg = error_forground end
	display.print(tostring(title..value),left + pad,top + pad,font,fg,background, width)
end

function get_time(title, hh, mm, ss)
	local timeTab = {hh,mm,ss}
	local timeMax = {23,59,59}
	local timePtr = 1
	keys:start()
	while true do
		local value = string.format("%02d:%02d:%02d", timeTab[1], timeTab[2], timeTab[3])
		drow_box(title,value)
		local key = keys:getkey()
		if key ~= nil then
			if key == KEY.Q then return false
			elseif key == KEY.UP or key == KEY.WHEEL_UP then
				timeTab[timePtr] = timeTab[timePtr] + 1
				if timeTab[timePtr] > timeMax[timePtr] then timeTab[timePtr] = 0 end
			elseif key == KEY.DOWN or key == KEY.WHEEL_DOWN then
				timeTab[timePtr] = timeTab[timePtr] - 1
				if timeTab[timePtr] <= 0 then timeTab[timePtr] = timeMax[timePtr] end
			elseif key == KEY.LEFT or key == KEY.WHEEL_LEFT then
				timePtr = timePtr - 1
				if timePtr < 1 then timePtr = 3 end
			elseif key == KEY.RIGHT or key == KEY.WHEEL_RIGHT then
				timePtr = timePtr + 1
				if timePtr > 3 then timePtr = 1 end
			elseif key == KEY.SET then
				break
			end
        end
        task.yield(100)
	end
	keys:stop()
	display.clear()
	return timeTab
end

function main()
    menu.close()
    console.show()
    console.clear()

    log_start () -- Open log file
    log ("==> ML_TimeLapse.lua - Version : %s", Version)
    log ("%s - Log begin.",pretty_time(get_cur_secs()))
	print ("---------------------------------------------------")
	print (" ML_TimeLapse")
	print (" https://github.com/ozuntini/ML_TimeLapse")
	print (" Released under the GNU GPL")
    print ("---------------------------------------------------")
	

	console.hide()
	local timeTab = time_tab(get_cur_secs())
	timeTab = get_time("Start at : ", timeTab[1], timeTab[2], timeTab[3])
	console.show()

	if type(timeTab) == "table" then
		print (string.format("Get time = %02d:%02d:%02d", timeTab[1], timeTab[2], timeTab[3]))
	else
		print ("Error !")
	end
	
    print ("Press any key to exit.")
    key.wait()
    console.clear()
    console.hide()
    log ("%s - Normal exit.",pretty_time(get_cur_secs()))
	log_stop () -- close log file
end

keymenu = menu.new
{
    name   = "ML_TimeLapse",
    help   = "TimeLapse with ML ",
    select = function(this) task.create(main) end,
}