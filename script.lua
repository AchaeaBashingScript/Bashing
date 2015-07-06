local debugEnabled = false
local directTargetAccess = {}
local afflictions = {
	weakness = {
		colour = "purple",
		timer = 7
	},
	sensitivity = {
		colour = "gold",
		timer = 8
	},
	recklessness = {
		colour = "gold",
		timer = 9
	},
	aeon = {
		colour = "gold",
		timer = 6
	},
	feared = {
		colour = "gold",
		timer = 8
	},
	clumsy = {
		colour = "gold",
		timer = 7
	},
	inhibit = {
		colour = "gold",
		timer = 9
	},
	charm = {
		colour = "gold",
		timer = 5
	},
	stun = {
		colour = "gold",
		timer = 4
	},
}

local requestSkillDetails = {}
local battlerageSkills = {}
local rage = 0

local race = ""
local class = ""

keneanung = keneanung or {}
keneanung.bashing = {}
keneanung.bashing.configuration = {}
keneanung.bashing.configuration.priorities = {}
keneanung.bashing.targetList = {}
keneanung.bashing.systems = {}
keneanung.bashing.battlerage = {}

keneanung.bashing.attacking = 0
keneanung.bashing.damage = 0
keneanung.bashing.attacks = 0
keneanung.bashing.healing = 0
keneanung.bashing.lastHealth = 0
keneanung.bashing.usedRageAttack = false

keneanung.bashing.configuration.enabled = false
keneanung.bashing.configuration.warning = 500
keneanung.bashing.configuration.fleeing = 300
keneanung.bashing.configuration.autoflee = true
keneanung.bashing.configuration.autoraze = false
keneanung.bashing.configuration.razecommand = "none"
keneanung.bashing.configuration.attackcommand = "kill"
keneanung.bashing.configuration.system = "auto"
keneanung.bashing.configuration.filesToLoad = {}
keneanung.bashing.configuration.rageStrat = "simple"

local debugMessage = function(message, content)
	if not debugEnabled then return end
	echo(string.format("[%s]: %s", (debug.getinfo(2).name or "unknown"), message))
	if content then
		display(content)
	end
end

local kecho = function(what, command, popup)

	what = "\n<green>keneanung<reset>: " .. what
	if command then
		cechoLink(what, command, popup or "", true)
	else
		cecho(what)
	end

end

local requestNextSkillDetails = function()
	if #requestSkillDetails == 0 then return end
	sendGMCP(string.format([[Char.Skills.Get {"group": "battlerage", "name": "%s"}]], requestSkillDetails[1]))
	table.remove(requestSkillDetails,1)
end

keneanung.bashing.systems.svo = {

	startAttack = function()
		svo.addbalanceful("do next attack", keneanung.bashing.nextAttack)
		svo.donext()
	end,
	
	stopAttack = function()
		svo.removebalanceful("do next attack")
	end,
	
	flee = function()
		keneanung.bashing.systems.svo.stopAttack()
		svo.dofreefirst(keneanung.bashing.fleeDirection)
	end,
	
	warnFlee = function(avg)
		svo.boxDisplay("Better run or get ready to die!", "orange")
	end,
	
	notifyFlee = function(avg)
		svo.boxDisplay("Running as you have not enough health left.", "red")
	end,

	handleShield = function()
		keneanung.bashing.shield = true
	end,
	
	setup = function()
		
	end,
	
	teardown = function()
		
	end,
	
}

keneanung.bashing.systems.wundersys = {

	startAttack = function()
		if keneanung.bashing.attacking > 0 then
			enableTrigger(keneanung.bashing.systems.wundersys.queueTrigger)
			local command
			if keneanung.bashing.configuration.attackcommand:find("&tar") then
				command = keneanung.bashing.configuration.attackcommand
			else
				command = keneanung.bashing.configuration.attackcommand .. " &tar"
			end
			wsys.doradd(command)
 	 	end
	end,
	
	stopAttack = function()
		disableTrigger(keneanung.bashing.systems.wundersys.queueTrigger)
		wsys.dorclear()
	end,
	
	flee = function()
		keneanung.bashing.systems.wundersys.stopAttack()
		wsys.dofreeadd(keneanung.bashing.fleeDirection)
	end,
	
	warnFlee = function(avg)
		wsys.boxDisplay("Better run or get ready to die!", "orange")
	end,
	
	notifyFlee = function(avg)
		wsys.boxDisplay("Running as you have not enough health left.", "red")
	end,

	handleShield = function()
		if keneanung.bashing.configuration.autoraze then
			local command
			if keneanung.bashing.configuration.razecommand:find("&tar") then
				command = keneanung.bashing.configuration.razecommand
			else
				command = keneanung.bashing.configuration.razecommand .. " &tar"	
			end
			wsys.dofirst(command, 1)
		end
		keneanung.bashing.shield = true
	end,

	brokeShield = function()
		wsys.undo(true, 1)
	end,
	
	setup = function()
		keneanung.bashing.systems.wundersys.queueTrigger = tempTrigger("[System]: Running queued eqbal command: DOR",
			[[
			local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
			keneanung.bashing.attacks = keneanung.bashing.attacks + 1
			local avgDmg = keneanung.bashing.damage / keneanung.bashing.attacks
			local avgHeal = keneanung.bashing.healing / keneanung.bashing.attacks
			
			local estimatedDmg = avgDmg * 2 - avgHeal

			local fleeat = keneanung.bashing.calcFleeValue(keneanung.bashing.configuration.fleeing)

			local warnat = keneanung.bashing.calcFleeValue(keneanung.bashing.configuration.warning)

			if estimatedDmg > gmcp.Char.Vitals.hp - fleeat and keneanung.bashing.configuration.autoflee then

				system.notifyFlee(estimatedDmg)

				system.flee()

			else
				if estimatedDmg > gmcp.Char.Vitals.hp - warnat then

					system.warnFlee(estimatedDmg)

				end
			end
			]])
		disableTrigger(keneanung.bashing.systems.wundersys.queueTrigger)
		registerAnonymousEventHandler("do action run", "keneanung.bashing.systems.wundersys.doActionRun")
	end,
	
	teardown = function()
		if keneanung.bashing.systems.wundersys.queueTrigger then
			killTrigger(keneanung.bashing.systems.wundersys.queueTrigger)
		end
	end,

	doActionRun = function(_, command)
		local razecommand
		if keneanung.bashing.configuration.razecommand:find("&tar") then
			razecommand = keneanung.bashing.configuration.razecommand
		else
			razecommand = keneanung.bashing.configuration.razecommand .. " &tar"
		end
		display(command)
		display(razecommand)
		if command == razecommand then
			keneanung.bashing.shield = false
		end
		display(keneanung.bashing.shield)
	end,
}

local function sendRageAttack(attack)
	debugMessage("sending rage attack", attack)
	send(attack, false)
	keneanung.bashing.usedRageAttack = true
	tempTimer(1, "keneanung.bashing.usedRageAttack = false")
end

local function rageRazeFunction()
	if keneanung.bashing.shield then
		if keneanung.bashing.configuration.autorageraze and keneanung.bashing.rageAvailable(3) then
			send(battlerageSkills[3].command, false)
			keneanung.bashing.shield = false
			local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
			if system.brokeShield then
				system.brokeShield()
			end
			return true
		else
			return false
		end
	end
end

keneanung.bashing.battlerage.none = function(rage)
end

keneanung.bashing.battlerage.simple = function(rage)
	if keneanung.bashing.attacking == 0 then return end

	debugMessage("running 'simple' rage strategy",
		{
			rage = rage,
			shield = keneanung.bashing.shield,
			rageraze = keneanung.bashing.configuration.autorageraze,
			rageSkills = battlerageSkills
		}
	)

	if not rageRazeFunction() then
		if keneanung.bashing.rageAvailable(4) then
			sendRageAttack(battlerageSkills[4].command)
		elseif
			keneanung.bashing.rageAvailable(1) and
				((not battlerageSkills[4].skillKnown) or
				rage >= (battlerageSkills[1].rage + battlerageSkills[4].rage))
		then
			sendRageAttack(battlerageSkills[1].command)
		end
	end
end

keneanung.bashing.battlerage.simplereverse = function(rage)
	if keneanung.bashing.attacking == 0 then return end

	debugMessage("running 'simplereverse' rage strategy",
		{
			rage = rage,
			shield = keneanung.bashing.shield,
			rageraze = keneanung.bashing.configuration.autorageraze,
			rageSkills = battlerageSkills
		}
	)

	if not rageRazeFunction() then
		if keneanung.bashing.rageAvailable(1) then
			sendRageAttack(battlerageSkills[1].command)
		elseif keneanung.bashing.rageAvailable(4) then
			sendRageAttack(battlerageSkills[4].command)
		end
	end
end

local aliases = {
	["razecommand"]   = "keneanungra",
	["attackcommand"] = "keneanungki",
}

local getSystem = function(tbl, index)
	local systemName
	if index == "auto" then
		if svo then
			return keneanung.bashing.systems.svo
		elseif wsys and wsys.myVersion then
			return keneanung.bashing.systems.wundersys
		end
	end
	kecho("<orange>Something went completely wrong: You are using an unknown system ('"..index.."'). Please use 'kconfig bashing system <name>' to correct this.")
	return nil
end

setmetatable(keneanung.bashing.systems, { __index = getSystem } )

keneanung.bashing.addPossibleTarget = function(targetName)

	local prios = keneanung.bashing.configuration.priorities
	local area = gmcp.Room.Info.area

	if prios[area] == nil then
		prios[area] = {}
		kecho("Added the new area <red>" .. area .. "<reset> to the configuration.")
	end

	if not table.contains(prios[area], targetName) then
		
		local before = keneanung.bashing.idOnly(keneanung.bashing.targetList)
		
		table.insert(prios[area], targetName)
		kecho("Added the new possible target <red>" .. targetName .. "<reset> to the end of the priority list.")
		keneanung.bashing.configuration.priorities = prios

		keneanung.bashing.save()

		for _, item in ipairs(keneanung.bashing.room) do
			keneanung.bashing.addTarget(item)
		end
		
		local after = keneanung.bashing.idOnly(keneanung.bashing.targetList)

		keneanung.bashing.emitEventsIfChanged(before, after)
	end
end

keneanung.bashing.showAreas = function()
	keneanung.bashing.showAreasFiltered(keneanung.bashing.configuration.priorities)
end

keneanung.bashing.showAreasFiltered = function(filtered)

	kecho("Which area would you like to configure:\n")
	for area, _ in pairs(filtered) do
		cechoLink("   (<orange>" .. area .. "<reset>)\n",[[keneanung.bashing.managePrios("]]..area..[[")]],"Show priority list for '" .. area .."",true)
	end
end

keneanung.bashing.managePrios = function(area)

	local possibleMatches = {}
	for areaName, _ in pairs(keneanung.bashing.configuration.priorities) do
		if areaName:lower() == area:lower() then
			possibleMatches[areaName] = true
			break
		end
		if areaName:lower():find(area:lower()) then
			possibleMatches[areaName] = true
		end
	end

	if table.is_empty(possibleMatches) then
		kecho("No targets for <red>" .. area .. "<reset> found yet!\n")
		return
	elseif table.size(possibleMatches) == 1 then
		for areaName, _ in pairs(possibleMatches) do
			area = areaName
		end
	else
		keneanung.bashing.showAreasFiltered(possibleMatches)
		return
	end

	local prios = keneanung.bashing.configuration.priorities[area]

	kecho("Possible targets for <red>" .. area .. "<reset>:\n")
	for num, item in ipairs(prios) do
		echo("     ")
		cechoLink("<antique_white>(<light_blue>^^<antique_white>)", [[keneanung.bashing.shuffleUp("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step up.", true)
		echo(" ")
		cechoLink("<antique_white>(<red>vv<antique_white>)", [[keneanung.bashing.shuffleDown("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step down.", true)
		echo(" ")
		cechoLink("<antique_white>(<gold>DD<antique_white>)", [[keneanung.bashing.delete("]]..area..[[", ]] .. num .. [[)]], "Delete " .. item .. " from list.", true)
		resetFormat()
		echo(" " .. item .. "\n")
	end
end

keneanung.bashing.shuffleDown = function(area, num)

	local prios = keneanung.bashing.configuration.priorities[area]

	if num < #prios then
		prios[num], prios[num+1] =  prios[num+1], prios[num]
	end
	keneanung.bashing.save()

	keneanung.bashing.managePrios(area)

end

keneanung.bashing.shuffleUp = function(area, num)

	local prios = keneanung.bashing.configuration.priorities[area]

	if num > 1 then
		prios[num], prios[num-1] =  prios[num-1], prios[num]
	end
	keneanung.bashing.save()

	keneanung.bashing.managePrios(area)

end

keneanung.bashing.delete = function(area, num)

	local prios = keneanung.bashing.configuration.priorities[area]

	table.remove(prios, num)

	keneanung.bashing.save()

	keneanung.bashing.managePrios(area)
end

keneanung.bashing.save = function()
  if string.char(getMudletHomeDir():byte()) == "/" then
		_sep = "/"
  	else
		_sep = "\\"
   end -- if
  local savePath = getMudletHomeDir() .. _sep .. "keneanung_bashing.lua"
  table.save(savePath, keneanung.bashing.configuration)

end -- func

keneanung.bashing.load = function()
  if string.char(getMudletHomeDir():byte()) == "/"
   then _sep = "/"
    else _sep = "\\"
     end -- if
  local savePath = getMudletHomeDir() .. _sep .. "keneanung_bashing.lua"
  if (io.exists(savePath)) then
   table.load(savePath, keneanung.bashing.configuration)
  end -- if

end -- func

keneanung.bashing.showConfig = function()
	kecho(
		string.format(
			"Bashing is <red>%s<reset>",
			keneanung.bashing.configuration.enabled and "on" or "off"
		),
		"keneanung.bashing.toggle('enabled', 'Bashing')",
		string.format(
			"Turn bashing %s",
			keneanung.bashing.configuration.enabled and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Automatic fleeing is <red>%s<reset>",
			keneanung.bashing.configuration.autoflee and "on" or "off"
		),
		"keneanung.bashing.toggle('autoflee', 'Fleeing')",
		string.format(
			"Turn fleeing %s",
			keneanung.bashing.configuration.autoflee and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Warning at a security threshhold of <red>%s<reset> health",
			keneanung.bashing.configuration.warning
		),
		"clearCmdLine() appendCmdLine('kconfig bashing warnat ')",
		"Set warn threshold."
	)

	kecho(
		string.format(
			"Fleeing at a security threshhold of <red>%s<reset> health",
			keneanung.bashing.configuration.fleeing
		),
		"clearCmdLine() appendCmdLine('kconfig bashing fleeat ')",
		"Set flee threshold."
	)

	kecho(
		string.format(
			"Attack is set to <red>%s<reset>",
			keneanung.bashing.configuration.attackcommand
		),
		"clearCmdLine() appendCmdLine('kconfig bashing attackcommand ')",
		"Set attack."
	)

	kecho(
		string.format(
			"Autoraze is <red>%s<reset>",
			keneanung.bashing.configuration.autoraze and "on" or "off"
		),
		"keneanung.bashing.toggle('autoraze', 'Autorazing')",
		string.format(
			"Turn autorazing %s",
			keneanung.bashing.configuration.autoraze and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Special attack on shielding is set to <red>%s<reset>",
			keneanung.bashing.configuration.razecommand
		),
		"clearCmdLine() appendCmdLine('kconfig bashing razecommand ')",
		"Set attack to raze shields."
	)

	kecho(
		string.format(
			"Razing shields with rage is <red>%s<reset>",
			keneanung.bashing.configuration.autorageraze and "on" or "off"
		),
		"keneanung.bashing.toggle('autorageraze', 'Autorazing with rage')",
		string.format(
			"Turn autorazing with rage %s",
			keneanung.bashing.configuration.autorageraze and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Currently using this battlerage strategy: <red>%s<reset>",
			keneanung.bashing.configuration.rageStrat
		),
		"clearCmdLine() appendCmdLine('kconfig bashing ragestrat ')",
		"Set battlerage strategy to use."
	)

	kecho(
		string.format(
			"Currently using this system: <red>%s<reset>",
			keneanung.bashing.configuration.system
		),
		"clearCmdLine() appendCmdLine('kconfig bashing system ')",
		"Set system to use."
	)

	echo("\n")

	kecho("Loading these additional files on startup:    ")
	cechoLink("(<yellow>Add new file<reset>)", "keneanung.bashing.addFile()", "Add a new file to load on startup", true)
	for num, path in ipairs(keneanung.bashing.configuration.filesToLoad) do
		echo("\n             " .. path .. " (")
		cechoLink("(<red>Delete<reset>)", "keneanung.bashing.deleteFile(" .. num .. ")", "Don't load this file anymore", true)
	end
	echo("\n")

	kecho("Version: <red>" .. keneanung.bashing.version .. "<reset>")
end

keneanung.bashing.toggle = function(what, print)
	keneanung.bashing.configuration[what] = not keneanung.bashing.configuration[what]
	kecho(print .. " <red>" .. (keneanung.bashing.configuration[what] and "enabled" or "disabled") .. "\n" )
	keneanung.bashing.save()
end

keneanung.bashing.shielded = function(what)
	if what == keneanung.bashing.targetList[keneanung.bashing.attacking].name then
		local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
		system.handleShield()
	end
end

keneanung.bashing.flee = function()
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
	system.flee()
	keneanung.bashing.clearTarget()
	kecho("New order. Tactical retreat.\n")
end

keneanung.bashing.attackButton = function()
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
	if keneanung.bashing.attacking == 0 then
		keneanung.bashing.setTarget()
		system.startAttack()
		kecho("Nothing will stand in our way.\n")
	else
		keneanung.bashing.clearTarget()
		system.stopAttack()
		kecho("Lets save them for later.\n")
	end
end

keneanung.bashing.setFlee = function(where)
	keneanung.bashing.fleeDirection = where
	kecho("Fleeing to the <red>" .. keneanung.bashing.fleeDirection .. "\n" )
end

keneanung.bashing.setThreshold = function(newValue, what)
	keneanung.bashing.configuration[what] = matches[2]
	kecho(what:title().." with a security threshhold of <red>" .. keneanung.bashing.configuration[what] .. "<reset> health\n" )
	keneanung.bashing.save()
end

keneanung.bashing.nextAttack = function()
	if keneanung.bashing.configuration.enabled == false then
		return false
	end
	
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]

	keneanung.bashing.attacks = keneanung.bashing.attacks + 1

	if #keneanung.bashing.targetList > 0 then

		local avg = keneanung.bashing.damage / keneanung.bashing.attacks

		local fleeat = keneanung.bashing.calcFleeValue(keneanung.bashing.configuration.fleeing)

		local warnat = keneanung.bashing.calcFleeValue(keneanung.bashing.configuration.warning)

		if avg > gmcp.Char.Vitals.hp - fleeat and keneanung.bashing.configuration.autoflee then

			system.notifyFlee(avg)

			system.flee()

		else
			if avg > gmcp.Char.Vitals.hp - warnat then

				system.warnFlee(avg)

			end
		
			local attack = (keneanung.bashing.shield and keneanung.bashing.configuration.autoraze) and "keneanungra" or "keneanungki"
			send(attack, false)
			keneanung.bashing.shield = false
			return true

		end

	end

	keneanung.bashing.clearTarget()
	system.stopAttack()
	return false

end

keneanung.bashing.roomItemCallback = function(event)

	if gmcp.Char.Items[event:match("%w+$")].location ~= "room" or keneanung.bashing.configuration.enabled == false then
		return
	end

	debugMessage(event, { room=keneanung.bashing.room, targetList=keneanung.bashing.targetList })

	local backup = keneanung.bashing.targetList
	local directAccessBackup = directTargetAccess
	local before = keneanung.bashing.idOnly(keneanung.bashing.targetList)

	if(event == "gmcp.Char.Items.Add") then
		local item = gmcp.Char.Items.Add.item
		keneanung.bashing.room[#keneanung.bashing.room + 1] = item
		keneanung.bashing.addTarget(item)
	end

	if(event == "gmcp.Char.Items.List") then
		local targetList = {}
		-- make sure our targets stay at the same place!
		for index, targ in ipairs(keneanung.bashing.targetList) do
			if index > keneanung.bashing.attacking then
				break
			end
			targetList[#targetList + 1] = targ
		end
		keneanung.bashing.targetList = targetList
		keneanung.bashing.room = {}
		for _, item in ipairs(gmcp.Char.Items.List.items) do
			keneanung.bashing.room[#keneanung.bashing.room + 1] = item
			keneanung.bashing.addTarget(item)
		end
	end

	if(event == "gmcp.Char.Items.Remove") then
		local item = gmcp.Char.Items.Remove.item
		for num, itemRoom in ipairs(keneanung.bashing.room) do
			if (itemRoom.id * 1) == (item.id * 1) then
				table.remove(keneanung.bashing.room, num)
				break
			end
		end

		keneanung.bashing.removeTarget(item)
	end

	local after = keneanung.bashing.idOnly(keneanung.bashing.targetList)

	debugMessage("got before and after", {before=before, after=after, intersection=table.n_intersection(before, after)})

	if #before == #after and #table.n_intersection(before, after) == #before then
		keneanung.bashing.targetList = backup
		directTargetAccess = directAccessBackup
		return
	end

	keneanung.bashing.emitEventsIfChanged(before, after)

	debugMessage("after", { room=keneanung.bashing.room, targetList=keneanung.bashing.targetList })
end

keneanung.bashing.emitEventsIfChanged = function( before, after)
	if keneanung.bashing.difference(before, after) then
		raiseEvent("keneanung.bashing.targetList.changed")
		if before[1] ~= after[1] then
			raiseEvent("keneanung.bashing.targetList.firstChanged", after[1])
		end

	end
end

keneanung.bashing.difference = function( list1, list2 )

	if #list1 ~= #list2 then
		return true
	end

	for num, value in ipairs(list1) do
		if value ~= list2[num] then return true end
	end

	return false

end

keneanung.bashing.idOnly = function( list )

	local ret = {}

	for _, value in ipairs(list) do

		table.insert(ret, value.id)

	end

	return ret

end

keneanung.bashing.addTarget = function(item)

	local targets = keneanung.bashing.targetList
	local prios = keneanung.bashing.configuration.priorities[gmcp.Room.Info.area]
	local insertAt

	if not prios then
		return
	end

	local targetPrio = table.index_of(prios, item.name)

	if not targetPrio then
		return
	end

	local targetObject = { id = item.id, name = item.name, affs = {} }

	if #targets == 0 then
		table.insert(targets, targetObject)
	else

		-- Small safeguard against adding something twice
		for _, tar in ipairs(targets) do
			if tar.id == item.id then
				return
			end
		end
		
		local iStart,iEnd,iMid = 1,#targets,0
		local found = false
		-- Binary Search
		while iStart <= iEnd do
			-- calculate middle
			iMid = math.floor( (iStart+iEnd)/2 )
			-- get compare value
			local existingPrio = table.index_of(prios, targets[iMid].name)
			-- get all values that match
			if targetPrio == existingPrio then
				insertAt = iMid
				found = true
				break
			elseif existingPrio == nil or targetPrio < existingPrio then
				iEnd = iMid - 1
			else
				iStart = iMid + 1
			end

		end

		if not found then
			insertAt = iStart
		end

		if insertAt <= keneanung.bashing.attacking and #keneanung.bashing.targetList >= keneanung.bashing.attacking then
			insertAt = keneanung.bashing.attacking + 1
		end

		table.insert(targets, insertAt, targetObject)

	end

	if directTargetAccess[item.id] then
		for aff, timer in pairs(directTargetAccess[item.id].affs) do
			targetObject[aff] = timer
		end
	end

	directTargetAccess[item.id] = targetObject

	keneanung.bashing.targetList = targets

end

keneanung.bashing.removeTarget = function(item)

	local targets = keneanung.bashing.targetList
	local number

	for num, itemTarget in ipairs(targets) do
		if (itemTarget.id * 1) == (item.id * 1) then
			number = num
			break
		end
	end

	if number then
		table.remove(targets, number)
		if number <= keneanung.bashing.attacking then
			keneanung.bashing.attacking = keneanung.bashing.attacking - 1
			keneanung.bashing.setTarget()
		end
		for _, timer in pairs(directTargetAccess[item.id].affs) do
			killTimer(timer)
		end
		directTargetAccess[item.id] = nil
	end

	keneanung.bashing.targetList = targets

end

keneanung.bashing.prioListChangedCallback = function()
	kecho("Priority list changed to:\n")
	for _, tar in ipairs(keneanung.bashing.targetList) do
		cecho("	<red>" .. tar.name .. "<reset>\n")
	end
end

keneanung.bashing.roomMessageCallback = function()
	if keneanung.bashing.lastRoom == nil then
		keneanung.bashing.lastRoom = gmcp.Room.Info.num
		keneanung.bashing.fleeDirection = "north"
	end

	if keneanung.bashing.lastRoom == gmcp.Room.Info.num then
		return
	end

	keneanung.bashing.damage = 0
	keneanung.bashing.healing = 0
	keneanung.bashing.attacks = 0
	keneanung.bashing.lastHealth = gmcp.Char.Vitals.hp * 1
	keneanung.bashing.shield = false
	if keneanung.bashing.attacking > 0 then
		keneanung.bashing.clearTarget()
		local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
		system.stopAttack()
	end

	local exits = getRoomExits(gmcp.Room.Info.num) or gmcp.Room.Info.exits
	local found = false

	if exits ~= {} then
		for direction, num in pairs(exits) do
			if num == keneanung.bashing.lastRoom then
				keneanung.bashing.fleeDirection = direction
				found = true
				break
			end
		end
	end

	if not found and not gmcp.Room.Info.ohmap then
		kecho("<red>WARNING:<reset> No exit to flee found, reusing <red>" .. keneanung.bashing.fleeDirection .. "<reset>.\n")
	end

	keneanung.bashing.lastRoom = gmcp.Room.Info.num
end

keneanung.bashing.vitalsChangeRecord = function()

	if keneanung.bashing.attacking == 0 then return end

	local difference = keneanung.bashing.lastHealth - gmcp.Char.Vitals.hp

	if difference > 0 then
		keneanung.bashing.damage = keneanung.bashing.damage + difference
	elseif difference < 0 then
		keneanung.bashing.healing = keneanung.bashing.healing + math.abs(difference)
	end

	keneanung.bashing.lastHealth = gmcp.Char.Vitals.hp * 1

	for _, stat in ipairs(gmcp.Char.Vitals.charstats) do
		local rageAmount = stat:match("^Rage: (%d+)$")
		if rageAmount then
			rage = tonumber(rageAmount)
			break
		end
	end

	keneanung.bashing.battlerage[keneanung.bashing.configuration.rageStrat](rage)

end

keneanung.bashing.buttonActionsCallback = function()
	keneanung.bashing.battlerage[keneanung.bashing.configuration.rageStrat](rage)
end

keneanung.bashing.charStatusCallback = function()
	local somethingChanged = false
	if race ~= gmcp.Char.Status.race then
		debugMessage("Race changed")
		somethingChanged = true
		race = gmcp.Char.Status.race
	end

	if class ~= gmcp.Char.Status.class then
		debugMessage("Class changed")
		somethingChanged = true
		class = gmcp.Char.Status.class
	end

	if somethingChanged then
		sendGMCP([[Char.Skills.Get {"group":"battlerage"}]]) -- rerequest battlerage abilities
	end
end

keneanung.bashing.setCommand = function(command, what)
	keneanung.bashing.configuration[command] = what
	kecho(command .. " is now <red>" .. keneanung.bashing.configuration[command] .. "<reset>\n" )
	keneanung.bashing.setAlias(command)
	keneanung.bashing.save()
end

keneanung.bashing.setTarget = function()
	if #keneanung.bashing.targetList == 0 then
		local tar
		local targetSet = false

		if target ~= nil and target ~='' then
			tar = target
		elseif gmcp.Char.Status.target ~= "None" then
			tar = gmcp.Char.Status.target
		end

		if tar ~= nil then

			for _, item in ipairs(keneanung.bashing.room) do
				if item.attrib and item.attrib:find("m") and item.name:lower():find(tar:lower()) then
					keneanung.bashing.targetList[#keneanung.bashing.targetList + 1]= {
						id = item.id,
						name = item.name
					}
					targetSet = true
				end
			end
		end
		if not targetSet then
			keneanung.bashing.clearTarget()
			local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
			system.stopAttack()
			return
		end
	end
	if keneanung.bashing.attacking == 0 or keneanung.bashing.targetList[keneanung.bashing.attacking].id ~= gmcp.Char.Status.target then
		keneanung.bashing.attacking = keneanung.bashing.attacking + 1
	end
	debugMessage("setting target", keneanung.bashing.targetList[keneanung.bashing.attacking])
	sendGMCP('IRE.Target.Set "' .. keneanung.bashing.targetList[keneanung.bashing.attacking].id .. '"')
end

keneanung.bashing.clearTarget = function()
	if gmcp.IRE.Target and gmcp.IRE.Target.Set ~= "" then
		debugMessage("clearing target")
		sendGMCP('IRE.Target.Set "0"')
	end
	keneanung.bashing.attacking = 0
end

keneanung.bashing.login = function()
	gmod.enableModule("keneanung.bashing", "IRE.Target")
	sendGMCP([[Core.Supports.Add ["IRE.Target 1"] ]])   -- register the GMCP module independently from gmod.
	gmod.enableModule("keneanung.bashing", "IRE.Display")
	sendGMCP([[Core.Supports.Add ["IRE.Display 3"] ]])   -- register the GMCP module independently from gmod.
	sendGMCP([[Char.Skills.Get {"group":"battlerage"}]])
	keneanung.bashing.setAlias("attackcommand")
	keneanung.bashing.setAlias("razecommand")
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
	system.setup()
end

keneanung.bashing.setAlias = function(command)
	local attackCommand
	if keneanung.bashing.configuration[command]:find("&tar") then
		attackCommand = keneanung.bashing.configuration[command]
	else
		attackCommand = keneanung.bashing.configuration[command] .. " &tar"
	end
	send(string.format("setalias %s %s", aliases[command], attackCommand), false)
end

keneanung.bashing.setSystem = function(systemName)
	if not rawget(keneanung.bashing.systems, systemName) and systemName ~= "auto" then
		kecho("<orange>System not changed as '" .. systemName .. "' is unknown.")
		return
	end
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
	if system then
		system.teardown()
	end
	keneanung.bashing.configuration.system = systemName
	kecho("Using <red>" .. keneanung.bashing.configuration.system .. "<reset> as queuing system.\n" )
	keneanung.bashing.save()
	system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
	system.setup()
end

keneanung.bashing.setRageStrat = function(strategyName)
	if not keneanung.bashing.battlerage[strategyName] then
		kecho("<orange>Battlerage strategy not changed as '" .. strategyName .. "' is unknown.")
		return
	end
	keneanung.bashing.configuration.rageStrat = strategyName
	keneanung.bashing.save()
	kecho("Using <red>" .. strategyName .. "<reset> as battlerage strategy.\n" )
end

keneanung.bashing.calcFleeValue = function(configValue)
	local isString = type(configValue) == "string"
	if isString and configValue:ends("%") then
		return configValue:match("%d+") * gmcp.Char.Vitals.maxhp / 100
	elseif isString and configValue:ends("d") then
		return configValue:match("(.-)d") * keneanung.bashing.damage / keneanung.bashing.attacks
	else
		return configValue * 1
	end
end

keneanung.bashing.addFile = function()
	local path = invokeFileDialog(true, "Which file do you want to add?")
	if path ~= "" then
		keneanung.bashing.configuration.filesToLoad[#keneanung.bashing.configuration.filesToLoad + 1] = path
	end
	keneanung.bashing.save()
end

keneanung.bashing.deleteFile = function(num)
	table.remove(keneanung.bashing.configuration.filesToLoad, num)
	keneanung.bashing.save()
end

keneanung.bashing.toggleDebug = function()
	debugEnabled = not debugEnabled
	kecho("Debug " .. (debugEnabled and "enabled" or "disabled"))
end

keneanung.bashing.addDenizenAffliction = function(denizen, affliction)
	debugMessage("New denizen affliction.", { denizen = denizen, affliction = affliction })

	local affObject = afflictions[affliction]
	debugMessage("associated affliction object", affObject)
	if not affObject then
		kecho("Affliction '<red>" .. affliction .. "<reset>' is not a known denizen affliction.")
		return
	end

	local denizenObject = directTargetAccess[denizen]
	debugMessage("associated denizen object from direct access", denizenObject)
	if not denizenObject then
		kecho("Denizen '<red>" .. denizen .. "<reset>' not in list of targets. Fallback is not yet implemented.")
		return
	end

	local isTarget = (keneanung.bashing.targetList[keneanung.bashing.attacking] == denizenObject)

	denizenObject.affs[affliction] = tempTimer(affObject.timer,
		string.format("keneanung.bashing.removeDenizenAffliction('%s', '%s')", denizenObject.id, affliction))

	kecho(string.format("<%s>%s%s<reset> <green>gained<reset> <%s>%s<reset>", isTarget and "OrangeRed" or "yellow",
		denizenObject.name, isTarget and " (your target)" or "", affObject.colour, affliction))
end

keneanung.bashing.removeDenizenAffliction = function(denizen, affliction)
	debugMessage("Remove denizen affliction.", { denizen = denizen, affliction = affliction })

	local affObject = afflictions[affliction]
	debugMessage("associated affliction object", affObject)
	if not affObject then
		kecho("Affliction '<red>" .. affliction .. "<reset>' is not a known denizen affliction.")
		return
	end

	local denizenObject = directTargetAccess[denizen]
	debugMessage("associated denizen object from direct access", denizenObject)
	if not denizenObject then
		kecho("Denizen '<red>" .. denizen .. "<reset>' not in list of targets.")
		return
	end

	local isTarget = (keneanung.bashing.targetList[keneanung.bashing.attacking] == denizenObject)

	killTimer(denizenObject.affs[affliction])
	kecho(string.format("<%s>%s%s<reset> <red>lost<reset> <%s>%s<reset>",
		isTarget and "OrangeRed" or "yellow", denizenObject.name, isTarget and " (your target)" or "", affObject.colour, affliction))
	denizenObject.affs[affliction] = nil
end

keneanung.bashing.getAfflictions = function(denizen)
	debugMessage("Returnung denizen affliction.", { denizen = denizen })

	local denizenObject = directTargetAccess[denizen]
	debugMessage("associated denizen object from direct access", denizenObject)
	if not denizenObject then
		kecho("Denizen '<red>" .. denizen .. "<reset>' not in list of targets.")
		return
	end

	local ret = {}
	for aff, _ in pairs(denizenObject.affs) do
		ret[#ret + 1] = aff
	end

	return ret
end

keneanung.bashing.handleSkillList = function()
	local skillList = gmcp.Char.Skills.List
	if skillList.group ~= "battlerage" then return end

	for index, skill in ipairs(skillList.list) do
		requestSkillDetails[index] = skill
	end
	battlerageSkills = {}
	requestNextSkillDetails()
end

keneanung.bashing.handleSkillInfo = function()
	local skillInfo = gmcp.Char.Skills.Info
	if skillInfo.group ~= "battlerage" then return end

	local cooldown = tonumber(skillInfo.info:match("(%d+\.%d+) seconds"))
	local rage = tonumber(skillInfo.info:match("(%d+) rage"))
	local command = skillInfo.info:match("\n(.-) <target>")
	local affliction = skillInfo.info:match("Gives denizen affliction: (%w+)")
	local affsUsed = {skillInfo.info:match("Uses denizen afflictions: (%w+) or (%w+)")}
	local skillKnown = skillInfo.info:find("*** You have not yet learned this ability ***", 1, true) == nil

	local rageObject = {
		cooldown = cooldown,
		rage = rage,
		command = command,
		affliction = affliction,
		affsUsed = affsUsed,
		name = skillInfo.skill,
		skillKnown = skillKnown
	}

	if #battlerageSkills == 0 or skillInfo.skill ~= battlerageSkills[#battlerageSkills].name then
		battlerageSkills[skillInfo.skill] = rageObject
		battlerageSkills[#battlerageSkills + 1] = rageObject
		debugMessage("added new battlerage skill complete list is here", battlerageSkills)
	else
		debugMessage("got double battlerage skill")
	end

	requestNextSkillDetails()
end

keneanung.bashing.rageAvailable = function(ability)
	if keneanung.bashing.usedRageAttack then return false end
	if type(ability) == "number" then
		ability = battlerageSkills[ability].name
	end
	for _, button in pairs(gmcp.IRE.Display.ButtonActions) do
		if button.text:lower() == ability:lower() then
			return button.highlight == 1
		end
	end
	return false
end

keneanung.bashing.load()
for _, file in ipairs(keneanung.bashing.configuration.filesToLoad) do
	dofile(file)
end
tempTimer(0, [[raiseEvent("keneanung.bashing.loaded")]])
