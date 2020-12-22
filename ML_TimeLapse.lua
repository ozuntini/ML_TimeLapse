-- Magic Lantern TimeLapse
Version = "1.0.3 "
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

-- Init de la table de config - Table de string
table_param = {}
table_param.iso_start = {} ; table_param.time_start = {} ; table_param.ramp_start = {} ; table_param.ramp_iso = {} ; table_param.ramp_end = {}
table_param.time_end = {} ; table_param.interval = {} ; table_param.mludelay = {}

-- Init de la table des iso
isoTab = {}

-- Position de la fenêtre de recap de la config
posit = {}
posit.top = 4
posit.left = 4
posit.bottom = posit.top
posit.right = posit.left
-- Ligne de config en cours
lineConfigNow = 0

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
	if (shutter_speed > 0.25)
	then
		shutter_speed = math.ceil(shutter_speed * 100) / 100
		text_time = tostring (shutter_speed)
	else
		shutter_speed = math.ceil(1 / shutter_speed)
		text_time = string.format ("1/%s", tostring (shutter_speed))
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
		return true
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
	if top < posit.bottom then top = posit.bottom + pad	end  -- Positionnement par rapport avec la fenêtre param
	local error = false
	-- Display a window
	display.rect(left-4,top-4,width+8,height+8,border,border)	-- contour
	display.rect(left,top,width,height,border,background)	-- rectangle de saisie
	local fg = foreground
    if error then fg = error_forground end
	display.print(tostring(title..value),left + pad,top + pad,font,fg,background, width)
end

-- Drow a window with parameters
function drow_table()
	local table = {}
	table[1] = {table_param.iso_start.name,string.format(" : %s iso",table_param.iso_start.value)}
	table[2] = {table_param.time_start.name,string.format(" : %02d:%02d:%02d D+%s",table_param.time_start.value[1],table_param.time_start.value[2],table_param.time_start.value[3],table_param.time_start.day)}
	table[3] = {table_param.ramp_start.name,string.format(" : %02d:%02d:%02d D+%s",table_param.ramp_start.value[1],table_param.ramp_start.value[2],table_param.ramp_start.value[3],table_param.ramp_start.day)}
	table[4] = {table_param.ramp_end.name,string.format(" : %02d:%02d:%02d D+%s",table_param.ramp_end.value[1],table_param.ramp_end.value[2],table_param.ramp_end.value[3],table_param.ramp_end.day)}
	table[5] = {table_param.ramp_iso.name,string.format(" : %s iso",table_param.ramp_iso.value)}
	table[6] = {table_param.time_end.name,string.format(" : %02d:%02d:%02d D+%s",table_param.time_end.value[1],table_param.time_end.value[2],table_param.time_end.value[3],table_param.time_end.day)}
	table[7] = {table_param.interval.name,string.format(" : %s s",table_param.interval.value)}
	table[8] = {table_param.mludelay.name,string.format(" : %s ms",table_param.mludelay.value)}
	local line = #table
	local i = 1
	local carmax1 = 1
	local carmax2 = 1
	while table[i] ~= nil do							-- index de la table avec un nombre max de caractère pour le champ 1 et 2
		if #table[carmax1][1] < #table[i][1] then carmax1 = i end
		if #table[carmax2][2] < #table[i][2] then carmax2 = i end
		i = i+1
	end
	local font = FONT.MED             				-- Type de fonte
    local border = COLOR.gray(75)
    local background = COLOR.gray(5)
    local foreground = COLOR.WHITE
    local highlight = COLOR.LIGHT_BLUE
	local pad = 10
    local height = (pad * 2) + (font.height * line)		-- Calcul de la hauteur de la box
	local width = font:width(table[carmax1][1]..table[carmax2][2]) + (pad * 2)	-- Calcul de la largeur de la box
	local width_name = font:width(table[carmax1][1])	-- largeur du nom du paramétre
	posit.bottom = height + posit.top
	posit.right = width + posit.left
	-- Display a window
	display.rect(posit.left-4,posit.top-4,width+8,height+8,border,border)	-- contour
	display.rect(posit.left,posit.top,width,height,border,background)		-- rectangle de saisie
	local top = posit.top
	for i, value in ipairs(table) do
		display.print(tostring(value[1]),posit.left + pad,top + pad,font,foreground,background, width)
		if i == lineConfigNow then
			display.print(tostring(value[2]),posit.left + pad + width_name,top + pad,font,highlight,background, width - width_name)
		else
			display.print(tostring(value[2]),posit.left + pad + width_name,top + pad,font,foreground,background, width - width_name)
		end
		top = top + font.height
	end
end

-- Drow a window for display title and time with highlight digit
function drow_time_box(title, digit1, digit2, digit3, hldigit)
	local value = string.format("%02d:%02d:%02d", digit1, digit2, digit3)
    local font = FONT.LARGE              -- Type de fonte
    local border = COLOR.gray(75)
    local background = COLOR.gray(5)
    local foreground = COLOR.WHITE
    local highlight = COLOR.LIGHT_BLUE
    local error_forground = COLOR.RED
	local pad = 20
    local height = pad * 2 + font.height -- Calcul de la hauteur de la box
    local width = font:width(title..value) + (pad * 2) -- Calcul de la largeur de la box
    local left = display.width // 2 - width // 2
	local top = display.height // 2 - height // 2
	if top < posit.bottom then top = posit.bottom + pad	end  -- Positionnement par rapport avec la fenêtre param
	local error = false
	-- Display a window
	display.rect(left-4,top-4,width+8,height+8,border,border)	-- contour
	display.rect(left,top,width,height,border,background)	-- rectangle de saisie
	local fg = foreground
	if error then fg = error_forground end
	display.print(tostring(title..value),left + pad,top + pad,font,fg,background, width) -- Affichage sans HL
	if hldigit == 1 then
		left = left + font:width(title) + pad
		value = string.format("%02d", digit1)
		width = font:width(value)
		display.print(tostring(value),left,top + pad,font,highlight,background, width)	-- Affichage du digit1 en hl
	elseif hldigit == 2 then
		value = string.format("%s%02d:", title, digit1)
		left = left + font:width(value) + pad
		value = string.format("%02d", digit2)
		width = font:width(value)
		display.print(tostring(value),left,top + pad,font,highlight,background, width)	-- Affichage du digit2 en hl
	elseif hldigit == 3 then
		value = string.format("%s%02d:%02d:", title, digit1, digit2)
		left = left + font:width(value) + pad
		value = string.format("%02d", digit3)
		width = font:width(value)
		display.print(tostring(value),left,top + pad,font,highlight,background, width)	-- Affichage du digit3
	else
		display.print(tostring(title..value),left + pad,top + pad,font,fg,background, width) -- Affichage sans HL
	end
end

-- Get a time selectioned by user and return a table h,m,s
function get_time(title, hh, mm, ss)
	drow_table()
	local timeTab = {hh,mm,ss}
	local timeMax = {23,59,59}
	local timePtr = 1
	timeTab[3] = 0
	keys:start()
	while true do
		local value = string.format("%02d:%02d:%02d", timeTab[1], timeTab[2], timeTab[3])
		--drow_box(title,value)
		drow_time_box(title, timeTab[1], timeTab[2], timeTab[3], timePtr)
		local key = keys:getkey()
		if key ~= nil then
			if key == KEY.Q then return "Q"
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

-- Get a parameter selectioned by user and return it and index
function get_param(title, paramTab)
	drow_table()
	local i = 1
	keys:start()
	while true do
		drow_box(title,paramTab[i])
		local key = keys:getkey()
		if key ~= nil then
			if key == KEY.Q then return "Q"
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
	return paramTab[i], i
end

function shoose_answer(title, table)
	local answer = get_param(title.." : ",table)
	if answer == "Q" then
		log ("%s - Get %s key Q pressed => Exit !",pretty_time(get_cur_secs()),title)
		return "Q" -- Sortie demandée
	end
	log ("%s - Get %s : %s",pretty_time(get_cur_secs()), title, answer)
	return answer
end

function shoose_value(param, table)
	param.value, param.index = get_param(param.name.." : ",table)
	if param.value == "Q" then
		log ("%s - Get %s key Q pressed => Exit !",pretty_time(get_cur_secs()),param.name)
		return "Q" -- Sortie demandée
	elseif type(param.value) == "number" then
		log ("%s - Get %s value : %s index : %s",pretty_time(get_cur_secs()), param.name, param.value, param.index)
	else
		log ("%s - Get %s in Error !",pretty_time(get_cur_secs()), param.name)
		return true
	end
	return false
end

function shoose_time(param)
	param.value = get_time(param.name.." : ", param.value[1], param.value[2], param.value[3])
	if param.value == "Q" then
		log ("%s - Get %s key Q pressed => Exit !",pretty_time(get_cur_secs()),param.name)
		return "Q" -- Sortie demandée
	elseif type(param.value) == "table" then
		log ("%s - Get %s at %02d:%02d:%02d",pretty_time(get_cur_secs()), param.name, param.value[1], param.value[2], param.value[3])
		param.seconds = convert_second(param.value[1], param.value[2], param.value[3])	-- conversion en secondes
	else
		log ("%s - Get %s in Error !",pretty_time(get_cur_secs()),param.name)
		return true
	end
	return false
end

-- Mirror lockup function
function set_mirror_lockup(mirrorLockupDelay)
    if (mirrorLockupDelay > 0)
    then
        menu.set("Mirror Lockup", "MLU mode", "Always ON")
        menu.set("Mirror Lockup", "Handheld Shutter", "All values")
        menu.set("Mirror Lockup", "Handheld Delay", "1s")
        menu.set("Mirror Lockup", "Normal MLU Delay", "1s")
        menu.set("Shoot", "Mirror Lockup", "Always ON")
        log ("%s - Set mirror lockup ON. Delay = %s",pretty_time(get_cur_secs()), mirrorLockupDelay)
    else
        menu.set("Shoot", "Mirror Lockup", "OFF")
        log ("%s - Set mirror lockup OFF.",pretty_time(get_cur_secs()))
    end
end

-- Take a picture function
function take_shoot(iso, mluDelay) -- mluDelay = delay to wait after mirror lockup in ms
    camera.iso.value = iso
    if (mluDelay > 0)
    then
        key.press(KEY.HALFSHUTTER)
        key.press(KEY.FULLSHUTTER)
        log ("%s - Mirror Up",pretty_time(get_cur_secs()))
        msleep(mluDelay)
    end
    if (TestMode == 1)
    then
        log ("%s - NO Shoot! ISO: %s Aperture: %s shutter: %s Test Mode",pretty_time(get_cur_secs()), tostring(camera.iso.value), tostring(camera.aperture.value), pretty_shutter(camera.shutter.value))
	else
		log ("%s - Shoot! ISO: %s Aperture: %s shutter: %s",pretty_time(get_cur_secs()), tostring(camera.iso.value), tostring(camera.aperture.value), pretty_shutter(camera.shutter.value))
        camera.shoot(false) -- Shoot a picture
    end
    if (mluDelay > 0)
    then
        key.press(KEY.UNPRESS_HALFSHUTTER)
        key.press(KEY.UNPRESS_FULLSHUTTER)
    end
end

-- Read Boucle and Photo line and do action
function do_action()

    -- Les paramètres sont chargés on gère le mirror lockup
	set_mirror_lockup(table_param.mludelay.value)
	
	-- Calcul des différents référentiels de temps
	local time_now = get_cur_secs()
	local relativ_start = table_param.time_start.seconds + (table_param.time_start.day * 86400) - time_now
	local relativ_startramp = table_param.ramp_start.seconds + (table_param.ramp_start.day * 86400) - time_now
	local relativ_stopramp = table_param.ramp_end.seconds + (table_param.ramp_end.day * 86400) - time_now
	local relativ_stop = table_param.time_end.seconds + (table_param.time_end.day * 86400) - time_now

	local time_zero = dryos.clock

	local duration_to_go = relativ_start - (dryos.clock - time_zero)
	local duration_start = relativ_startramp - relativ_start
	local duration_ramp = relativ_stopramp - relativ_startramp
	local duration_stop = relativ_stop - relativ_stopramp

	log ("%s - Relativ : Zero : %s Start : %s Startramp : %s Stopramp : %s Stop : %s",pretty_time(get_cur_secs()), time_zero , relativ_start, relativ_startramp, relativ_stopramp, relativ_stop)
	log ("%s - Duration = To go : %s Start : %s Ramp : %s Stop : %s",pretty_time(get_cur_secs()), duration_to_go, duration_start, duration_ramp, duration_stop)

    -- On boucle tant que nous ne sommes pas dans le bon créneau horaire
    local counter = 0
    while ((dryos.clock - time_zero) < (relativ_start - (table_param.mludelay.value/1000)))
	do  -- Pas encore l'heure on attend 0.25 seconde
        counter = counter + 1
        if (counter >= 80) -- Affiche Waiting toutes les 20s
        then
            display.notify_box("Waiting "..(relativ_start - (dryos.clock - time_zero)), 2000)
            counter = 0
        end
        msleep(250)
	end
	-- Boucle de prise de vues
	local shootTime = (dryos.clock - time_zero)
	local stepNumber = 0
	while ((dryos.clock - time_zero) <= relativ_stop)
	do
		shootTime = (dryos.clock - time_zero)
		if (shootTime < relativ_startramp)
		then
			--
			take_shoot(table_param.iso_start.value, table_param.mludelay.value)
		elseif (shootTime >= relativ_startramp) and (shootTime < relativ_stopramp) then
			stepNumber = math.ceil((dryos.clock - time_zero - relativ_startramp) / (duration_ramp/(table_param.ramp_iso.index - table_param.iso_start.index)))
			stepNumber = table_param.iso_start.index + stepNumber
			if table_param.iso_start.index > table_param.ramp_iso.index
			then
				if stepNumber < table_param.ramp_iso.index then
					stepNumber = table_param.ramp_iso.index
				end
			else
				if stepNumber > table_param.ramp_iso.index then
					stepNumber = table_param.ramp_iso.index
				end
			end
			--
			take_shoot(isoTab[stepNumber], table_param.mludelay.value)
		elseif (shootTime >= relativ_stopramp) and (shootTime <= relativ_stop) then
			--
			take_shoot(table_param.ramp_iso.value, table_param.mludelay.value)
		end
		while ((shootTime + table_param.interval.value -1 ) >= (dryos.clock - time_zero)) -- interval -1 pour prendre en compte le délais de prise de vue
        do
            msleep(500) -- Wait 1/2 s
        end
	end
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
	local error = false

	-- Etape 1 constitution des tables
	-- ISO
		-- Création d'une table théorique de valeurs d'ISO
	if camera.model_short == "6D" then
		isoTab = {50,100,125,160,200,250,320,400,500,640,800,1000,1250,1600,2000,2500,3200,
				4000,5000,6400,8000,10000,12800,16000,20000,25600,40000,51200,102400}
	else
		isoTab = {50,100,125,160,200,250,320,400,500,640,800,1000,1250,1600,2000,2500,3200,
				4000,5000,6400,8000}
	end
		-- Constitution de la table réel (possible avec ce boitier) de valeurs d'ISO
	isoTab = make_param_table("iso",isoTab)
	if type(isoTab) == "table" then
		log ("%s - ISO Table = %s values",pretty_time(get_cur_secs()), #isoTab)
	else
		print ("Error !")
		log ("%s - ISO Table in Error !",pretty_time(get_cur_secs()))
		error = true
	end	-- isoTab est maintenant la liste des valeurs possibles d'ISO
	-- Intervalles
		-- Création d'une table d'intervalles possibles en secondes
	local interval = {}
	local i = 1
	while i <= 100 do
		interval[i] = i
		i = i + 1
	end	-- interval est maintenant la liste des intervalles possibles dans ce programme
	-- Mirror Lockup Delay
		-- Création d'une tables de délais d'attente pour le mirro lockup
	local mluDelay = {0,100,200,300,400,500,1000,1500,2000}
		-- mludelay est maintenant la liste des délais d'attente possible dans ce programme

	-- Constitution des noms des différents paramétres
	table_param.iso_start.name = "Start ISO" ; table_param.iso_start.value = camera.iso.value				-- ISO value au début du cycle
	table_param.time_start.name = "Time to start" ; table_param.time_start.value = time_tab(math.ceil((get_cur_secs()+120)/60)*60) ; table_param.time_start.day = 0	-- Start Time
	table_param.ramp_start.name = "Start Ramp" ; table_param.ramp_start.value = {0,0,0} ; table_param.ramp_start.day = 0	-- Ramp start time
	table_param.ramp_iso.name = "End ISO" ; table_param.ramp_iso.value = camera.iso.value					-- End ramp ISO value
	table_param.ramp_end.name = "Stop Ramp" ; table_param.ramp_end.value = {0,0,0} ; table_param.ramp_end.day = 0	-- Ramp end value
	table_param.time_end.name = "Time to stop" ; table_param.time_end.value = {0,0,0} ; table_param.time_end.day = 0	-- End Time
	table_param.interval.name = "Interval" ; table_param.interval.value = 0									-- Interval in s
	table_param.mludelay.name = "MLU Delay" ; table_param.mludelay.value = 0								-- Mirro lockup delay in ms

	while error ~= true or error ~= "Q" do
		-- Etape 2 création de la conf de début de cycle
			-- Saisie des ISO au début du cycle
		lineConfigNow = 1
		error = shoose_value(table_param.iso_start,isoTab)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.iso_start.name, LoggingFilename))
			break
		end
			-- Saisie de l'heure de début du cycle
		lineConfigNow = 2
		error = shoose_time(table_param.time_start)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.time_start.name, LoggingFilename))
			break
		end
		-- Gestion du jour, attention pas de gestion du changement d'année
		if table_param.time_start.seconds > get_cur_secs() then
			table_param.time_start.day = 0
		else
			table_param.time_start.day = table_param.time_start.day + 1
		end
			-- Recap start config
		log ("%s - Start at %ss and %s ISO",pretty_time(get_cur_secs()), table_param.time_start.seconds, table_param.iso_start.value)
			-- Nous avons ISO et heure de début de cycle

		-- Etape 3 création de la conf de ramping
			-- Saisie de l'heure de début de ramping
		lineConfigNow = 3
		table_param.ramp_start.value = table_param.time_start.value												-- set Time to Start ramping
		table_param.ramp_start.day = table_param.time_start.day
		error = shoose_time(table_param.ramp_start)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.ramp_start.name, LoggingFilename))
			break
		end
		-- Gestion du jour, attention pas de gestion du changement d'année
		if table_param.ramp_start.seconds > table_param.time_start.seconds then
			table_param.ramp_start.day = table_param.time_start.day
		else
			table_param.ramp_start.day = table_param.time_start.day + 1
		end
			-- Saisie de l'heure de fin de ramping
		lineConfigNow = 4
		table_param.ramp_end.value = table_param.ramp_start.value												-- set Time to End ramping
		table_param.ramp_end.day = table_param.ramp_start.day
		error = shoose_time(table_param.ramp_end)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.ramp_end.name, LoggingFilename))
			break
		end
		-- Gestion du jour, attention pas de gestion du changement d'année
		if table_param.ramp_end.seconds > table_param.ramp_start.seconds
		then
			table_param.ramp_end.day = table_param.ramp_start.day
		else
			table_param.ramp_end.day = table_param.ramp_start.day + 1
		end
			-- Saisie des ISO en fin de ramping
		lineConfigNow = 5
		table_param.ramp_iso.value = table_param.iso_start.value												-- set ISO value en fin de ramping
		error = shoose_value(table_param.ramp_iso,isoTab)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.ramp_iso.name, LoggingFilename))
			break
		end
			-- Recap ramp config
		log ("%s - Ramping Start at %ss and finish at %ss with %s ISO",pretty_time(get_cur_secs()), table_param.ramp_start.seconds, table_param.ramp_end.seconds, table_param.ramp_iso.value)
			-- Nous avons heure de début et de fin et ISO du Ramping

		-- Etape 4 création de la conf de fin de cycle
			-- Saisie de l'heure de fin de cycle
		lineConfigNow = 6
		table_param.time_end.value = table_param.ramp_end.value													-- set Time to End
		table_param.time_end.day = table_param.ramp_end.day
		error = shoose_time(table_param.time_end)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.time_end.name, LoggingFilename))
			break
		end
		-- Gestion du jour, attention pas de gestion du changement d'année
		if table_param.time_end.seconds > table_param.ramp_end.seconds then
			table_param.time_end.day = table_param.ramp_end.day
		else
			table_param.time_end.day = table_param.ramp_end.day + 1
		end
			-- Recap ramp config
		log ("%s - End at %ss",pretty_time(get_cur_secs()), table_param.time_end.seconds)
			-- Nous avons l'heure de fin de cycle

		-- Etape 5 Interval and MLU delay
			-- Saisie de la valeur de l'intervalle
		lineConfigNow = 7
		error = shoose_value(table_param.interval,interval)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.interval.name, LoggingFilename))
			break
		end
			-- Saisie du mirror lockup
		lineConfigNow = 8
		error = shoose_value(table_param.mludelay,mluDelay)
		-- Gesion de la sortie
		if error == "Q" then
			print("key Q pressed => Exit !")
			break
		elseif error then
			print(string.format("Error on %s exit application. See %s",table_param.mludelay.name, LoggingFilename))
			break
		end
			-- Recap interval and mludelay config
		log ("%s - %s = %ss and %s = %sms",pretty_time(get_cur_secs()), table_param.interval.name, table_param.interval.value, table_param.mludelay.name, table_param.mludelay.value)
			-- Nous avons l'intervalle et le MLU Delay

		-- Etape 6 nous avons les paramêtres nous pouvons lancer le cycle
		log ("%s - Start at %ss and %s ISO",pretty_time(get_cur_secs()), table_param.time_start.seconds, table_param.iso_start.value)
		log ("%s - Start with Interval = %ss, MLU = %sms",pretty_time(get_cur_secs()), table_param.interval.value, table_param.mludelay.value)
		log ("%s - Ramp at : %ss and finish at : %ss with %s ISO",pretty_time(get_cur_secs()), table_param.ramp_start.seconds, table_param.ramp_end.seconds, table_param.ramp_iso.value)
		log ("%s - End at : %ss ",pretty_time(get_cur_secs()), table_param.time_end.seconds)

		lineConfigNow = 0
		drow_table()

		-- Start O/N
		local answer = shoose_answer("Start ?",{"Yes","No"})
		-- Gesion de la sortie
		if answer == "Q" then
			print("key Q pressed => Exit !")
			log ("%s - key Q pressed => Exit ! ",pretty_time(get_cur_secs()))
			break
		elseif answer == "Yes" then
			console.show()
			log ("%s - Start sequence ! ",pretty_time(get_cur_secs()))
			do_action()
			log ("%s - End sequence ! ",pretty_time(get_cur_secs()))
			break
		elseif answer == "No" then
			log ("%s - No Start back to config ! ",pretty_time(get_cur_secs()))
		else
			log ("%s - Error on %s, exit application ! ",pretty_time(get_cur_secs()), answer)
			break
		end
	end
	
	keys:stop()
	display.clear()
	console.show() 

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