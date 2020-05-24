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
LoggingFilename = "mltl.log"

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
		local filename = string.format(LoggingFilename)
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

-- Make a param table - iso , shutter , aperture
function make_param_table(param, theoTab)
	local initParam = 0
	-- Parameter state memorised
	if param == "iso" then initParam = camera.iso.value
	elseif param == "shutter" then initParam = camera.shutter.value
	elseif param == "aperture" then initParam = camera.aperture.value
	else
		log ("%s Parameter : %s not accepted !",pretty_time(get_cur_secs()), param)
		return false
	end
	log ("%s - get init parameter %s at %s",pretty_time(get_cur_secs()),param ,initParam)
	-- Collect accepted parameters
	local i = 1
	local j = 1
	local value = 0
	local realTab = {}
	while theoTab[i] ~= nil do
		if param == "iso" then
			camera.iso.value = theoTab[i]
			value = camera.iso.value
		elseif param == "shutter" then
			camera.shutter.value = theoTab[i]
			value = camera.shutter.value
		elseif param == "aperture" then
			camera.aperture.value = theoTab[i]
			value = camera.aperture.value
		end
        if realTab[j-1] ~= value then 
            realTab[j] = value
            j = j +1
        end
        i = i + 1
	end
	if param == "iso" then camera.iso.value = initParam
	elseif param == "shutter" then camera.shutter.value = initParam
	elseif param == "aperture" then camera.aperture.value = initParam
	end
	log ("%s - Apply init parameter %s at %s",pretty_time(get_cur_secs()),param ,initParam)
	log ("%s - Table %s updated with %s arguments",pretty_time(get_cur_secs()),param ,#realTab)
	return realTab
end

-- Drow a window for display title and value
function drow_box(title,value)
    local font = FONT.LARGE              -- Type de fonte
    local border = COLOR.gray(75)
    local background = COLOR.gray(5)
    local foreground = COLOR.WHITE
    local highlight = COLOR.BLUE
    local error_forground = COLOR.RED
	local pad = 20
    local height = pad * 2 + font.height -- Calcul de la hauteur de la box
    local width = font:width(title..value) + (pad * 2) -- Calcul de la largeur de la box
    local left = display.width // 2 - width // 2
	local top = display.height // 2 - height // 2
	local error = false
	-- Display a window
	display.rect(left-4,top-4,width+8,height+8,border,border)	-- contour
	display.rect(left,top,width,height,border,background)	-- rectangle de saisie
	local fg = foreground
    if error then fg = error_forground end
	display.print(tostring(title..value),left + pad,top + pad,font,fg,background, width)
end

-- Get a time selectioned by user and return a table h,m,s
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

-- Get a parameter selectioned by user and return it
function get_param(title, paramTab)
	local i = 1
	keys:start()
	while true do
		drow_box(title,paramTab[i])
		local key = keys:getkey()
		if key ~= nil then
			if key == KEY.Q then return false
			elseif key == KEY.UP or key == KEY.WHEEL_UP then
				i = i + 1
				if i > #paramTab then i = 1 end
			elseif key == KEY.DOWN or key == KEY.WHEEL_DOWN then
				i = i - 1
				if i < 1 then i = #paramTab end
			elseif key == KEY.SET then
				break
			end
        end
        task.yield(100)
	end
	keys:stop()
	display.clear()
	return paramTab[i]
end

-- Main
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

	-- Etape 1 constitution de la table des ISO
	-- Création d'une table théorique de valeurs d'ISO
	local isoTab = {50,100,125,160,200,250,320,400,500,640,800,1000,1250,1600,2000,2500,3200,4000,5000,6400,8000,10000,12800,16000,20000,25600,40000,51200,102400}
	-- Constitution de la table réel de valeur d'ISO
	isoTab = make_param_table("iso",isoTab)
	if type(isoTab) == "table" then
		log ("%s - ISO Table = %s values",pretty_time(get_cur_secs()), #isoTab)
	else
		print ("Error !")
		log ("%s - ISO Table in Error !",pretty_time(get_cur_secs()))
	end
	-- isoTab est maintenant la liste des valeurs possibles d'ISO

	-- Etape 2 création de la conf de début de cycle
	local isoValueStart = camera.iso.value		-- ISO value au début du cycle
	local timeStart = time_tab(get_cur_secs())	-- Start Time
	-- Saisie des ISO au début du cycle
	isoValueStart = get_param("Start ISO : ",isoTab)
	if type(isoValueStart) == "number" then
		log ("%s - Get ISO = %s",pretty_time(get_cur_secs()), isoValueStart)
	else
		print ("Error !")
		log ("%s - Get ISO in Error !",pretty_time(get_cur_secs()))
	end
	-- Saisie de l'heure de début du cycle
	timeStart = get_time("Start at : ", timeStart[1], timeStart[2], timeStart[3])
	if type(timeStart) == "table" then
		log ("%s - Get Time Start at %02d:%02d:%02d",pretty_time(get_cur_secs()), timeStart[1], timeStart[2], timeStart[3])
	else
		print ("Error !")
		log ("%s - Get Time Start in Error !",pretty_time(get_cur_secs()))
	end
	timeStart = convert_second(timeStart[1], timeStart[2], timeStart[3])	-- conversion en secondes
	log ("%s - Start at %ss and %s ISO",pretty_time(get_cur_secs()), timeStart, isoValueStart)
	-- Nous avons ISO et heure de début de cycle

	-- Etape 3 création de la conf de ramping
	local timeRampStart = time_tab(get_cur_secs())	-- Time to Start ramping
	local isoRampEnd = isoValueStart				-- ISO value en fin de ramping
	local timeRampEnd = timeRampStart				-- Time to End ramping
	-- Saisie de l'heure de début de ramping
	timeRampStart = get_time("Start Ramp at : ", timeRampStart[1], timeRampStart[2], timeRampStart[3])
	if type(timeRampStart) == "table" then
		log ("%s - Get Start Ramp at %02d:%02d:%02d",pretty_time(get_cur_secs()), timeRampStart[1], timeRampStart[2], timeRampStart[3])
	else
		print ("Error !")
		log ("%s - Get Start Ramp in Error !",pretty_time(get_cur_secs()))
	end
	timeRampStart = convert_second(timeRampStart[1], timeRampStart[2], timeRampStart[3])	-- conversion en secondes
	-- Saisie des ISO en fin de ramping
	isoRampEnd = get_param("End Ramp ISO : ",isoTab)
	if type(isoRampEnd) == "number" then
		log ("%s - Get ISO Ramp end = %s",pretty_time(get_cur_secs()), isoRampEnd)
	else
		print ("Error !")
		log ("%s - Get ISO Ramp end in Error !",pretty_time(get_cur_secs()))
	end
	-- Saisie de l'heure de fin de ramping
	timeRampEnd = get_time("End Ramp at : ", timeRampEnd[1], timeRampEnd[2], timeRampEnd[3])
	if type(timeRampEnd) == "table" then
		log ("%s - Get End Ramp at %02d:%02d:%02d",pretty_time(get_cur_secs()), timeRampEnd[1], timeRampEnd[2], timeRampEnd[3])
	else
		print ("Error !")
		log ("%s - Get End Ramp in Error !",pretty_time(get_cur_secs()))
	end
	timeRampEnd = convert_second(timeRampEnd[1], timeRampEnd[2], timeRampEnd[3])	-- conversion en secondes
	log ("%s - Ramping Start at %ss and finish at %ss ISO",pretty_time(get_cur_secs()),timeRampStart, timeRampEnd, isoRampEnd)
	-- Nous avons heure de début et de fin et ISO du Ramping

	-- Etape 4 création de la conf de fin de cycle
	local timeEnd = time_tab(get_cur_secs())	-- End Time
	-- Saisie de l'heure de fin du cycle
	timeEnd = get_time("End at : ", timeEnd[1], timeEnd[2], timeEnd[3])
	if type(timeEnd) == "table" then
		log ("%s - Get Time End at %02d:%02d:%02d",pretty_time(get_cur_secs()), timeEnd[1], timeEnd[2], timeEnd[3])
	else
		print ("Error !")
		log ("%s - Get Time End in Error !",pretty_time(get_cur_secs()))
	end
	timeEnd = convert_second(timeEnd[1], timeEnd[2], timeEnd[3])	-- conversion en secondes
	log ("%s - End at %ss",pretty_time(get_cur_secs()), timeEnd)
	-- Nous avons l'heure de fin de cycle

	-- Etape 5 saisie de la durée de l'intervalle
	local interval = {}
	local i = 1
	while i <= 100 do
		interval[i] = i
		i = i + 1
	end
	-- Saisie de l'intervalle
	interval = get_param("Interval = ",interval)
	if type(interval) == "number" then
		log ("%s - Get Interval = %s",pretty_time(get_cur_secs()), interval)
	else
		print ("Error !")
		log ("%s - Get Interval in Error !",pretty_time(get_cur_secs()))
	end
	log ("%s - Interval = %ss",pretty_time(get_cur_secs()), interval)
	-- Nous avons l'intervalle

	-- Etape 6 nous avons les paramêtres nous pouvons lancer le cycle
	log ("%s - Star at : %ss with %s ISO and Interval = %ss",pretty_time(get_cur_secs()), timeStart, isoValueStart, interval)
	log ("%s - Ramp at : %ss and finish at : %ss with %s ISO",pretty_time(get_cur_secs()), timeRampStart, timeRampEnd, isoRampEnd)
	log ("%s - End at : %ss ",pretty_time(get_cur_secs()), timeEnd)	

	keys:stop()
	display.clear()
	console.show() 

	msleep(2000)

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