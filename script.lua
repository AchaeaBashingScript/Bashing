local debugEnabled = false
local send = send
local directTargetAccess = {}
local afflictions = {
	weakness = {
		colour = "pale_green",
		timer = 7
	},
	sensitivity = {
		colour = "orange_red",
		timer = 8
	},
	recklessness = {
		colour = "yellow",
		timer = 15
	},
	aeon = {
		colour = "purple",
		timer = 6
	},
	fear = {
		colour = "orange",
		timer = 8
	},
	clumsiness = {
		colour = "forest_green",
		timer = 7
	},
	inhibit = {
		colour = "light_coral",
		timer = 9
	},
	charm = {
		colour = "magenta",
		timer = 5
	},
	stun = {
		colour = "black:yellow",
		timer = 4
	},
	amnesia = {
		colour = "LightGrey",
		timer = 5
	},
}

local nonBattlerageAttainmentSkills = {
	"Prevail",
	"Portals",
	"Battlerage",
	"Market",
	"Battle",
	"Limitedportals",
	"Independence",
	"Embrace",
	"Tradeskills",
	"Theft",
	"Craftsmanship",
	"Multiclass",
	"Sustenance",
	"Dragonhood",
	"Polymath",
}
local sessionGains = { }
local tripGains = { gold = 0, experience = 0 }

local requestSkillDetails = {}
local battlerageSkills = {}
local rage = 0

local race = ""
local class = ""
local lastGoldChange
local lastGold
local lastXp

local roomTargetStore = {}
local denizenCache = {}

local waintingForManualTargetTimer
local waitingForManualTarget = false

keneanung = keneanung or {}
keneanung.bashing = {}
keneanung.bashing.configuration = {}
keneanung.bashing.configuration.priorities = {}
keneanung.bashing.targetList = {}
keneanung.bashing.systems = {}
keneanung.bashing.battlerage = {}
keneanung.bashing.room = {}
keneanung.bashing.pausingAfflictions = {}

keneanung.bashing.attacking = 0
keneanung.bashing.damage = 0
keneanung.bashing.attacks = 0
keneanung.bashing.healing = 0
keneanung.bashing.lastHealth = 0
keneanung.bashing.usedRageAttack = false
keneanung.bashing.usedBalanceAttack = false

keneanung.bashing.configuration.enabled = false
keneanung.bashing.configuration.warning = 500
keneanung.bashing.configuration.fleeing = 300
keneanung.bashing.configuration.autoflee = true
keneanung.bashing.configuration.system = "auto"
keneanung.bashing.configuration.filesToLoad = {}
keneanung.bashing.configuration.targetLoyals = false
keneanung.bashing.configuration.lifetimeGains = { gold = 0, experience = 0 }
keneanung.bashing.configuration.manualTargetting = false
keneanung.bashing.configuration.waitForManualTarget = 2

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

local knownBattlerageSkillList = function()
	if #requestSkillDetails == 0 then
		return battlerageSkills[1].name .. " " .. battlerageSkills[2].name .. " " .. battlerageSkills[3].name .. " ".. battlerageSkills[4].name .. " ".. battlerageSkills[5].name .. " ".. battlerageSkills[6].name
	end
	return("processing... try doing some things!")
end

keneanung.bashing.configuration.requestBattlerageSkills = function()
	kecho("Requesting battlerage skills...\n")
	sendGMCP([[Char.Skills.Get {"group":"attainment"}]])
	send(" ")
end

local sortDepthswalkerBattlerage = function()

	debugMessage("sorting brage for walkers", {battlerageSkills = battlerageSkills})

	if class ~= "Depthswalker" or #battlerageSkills ~= 6 then return end
	battlerageSkills[2], battlerageSkills[3], battlerageSkills[4] = battlerageSkills["curse"], battlerageSkills["nakail"], battlerageSkills["lash"]

	battlerageSkills["curse"].affliction = "aeon"
	battlerageSkills["boinad"].affliction = "charm"

	battlerageSkills["erasure"].affsUsed = {
		"amnesia",
		"weakness"
	}

	debugMessage("sorted brage for walkers", {battlerageSkills = battlerageSkills})
end

local requestAllSkillDetails = function()
	while #requestSkillDetails > 0 do
		sendGMCP(string.format([[Char.Skills.Get {"group": "attainment", "name": "%s"}]], requestSkillDetails[1]))
		table.remove(requestSkillDetails,1)
	end
	send(" ",false)
end

local migrateTo1Point8 = function()
	if keneanung.bashing.configuration.attackcommand then
		local migratedConfig = {}
		migratedConfig.attackcommand = keneanung.bashing.configuration.attackcommand
		keneanung.bashing.configuration.attackcommand = nil
		migratedConfig.autoraze = keneanung.bashing.configuration.autoraze
		keneanung.bashing.configuration.autoraze = nil
		migratedConfig.razecommand = keneanung.bashing.configuration.razecommand
		keneanung.bashing.configuration.razecommand = nil
		migratedConfig.rageStrat = keneanung.bashing.configuration.rageStrat
		keneanung.bashing.configuration.rageStrat = nil
		migratedConfig.autorageraze = keneanung.bashing.configuration.autorageraze
		keneanung.bashing.configuration.autorageraze = nil
	end
end

local startAttack = function()
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
        system.startAttack()
	gmod.enableModule("keneanung.bashing", "IRE.Display")
	sendGMCP([[Core.Supports.Add ["IRE.Display 3"] ]])   -- register the GMCP module independently from gmod.
end

local stopAttack = function()
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
        system.stopAttack()
	gmod.disableModule("keneanung.bashing", "IRE.Display")
	sendGMCP([[Core.Supports.Remove ["IRE.Display"] ]])   -- unregister the GMCP module independently from gmod.
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
		send = function(command, echoback)
			debugMessage("send got called", {command = command, echoback = echoback })
			local useAlias = false
			if command == "keneanungki" then
				command = keneanung.bashing.configuration[class].attackcommand
				useAlias = true
			elseif command == "keneanungra" then
				command = keneanung.bashing.configuration[class].razecommand
				useAlias = true
			end
			if keneanung.bashing.attacking > 0 and useAlias then
				command = command:gsub("&tar", keneanung.bashing.targetList[keneanung.bashing.attacking].id)
			end

			local commands = command:split("/")
			for _, part in ipairs(commands) do
				svo.sendc(part, echoback)
			end
		end
	end,

	teardown = function()
		send = _G.send
	end,

	unpause = function()
		svo.donext()
	end

}

keneanung.bashing.systems.wundersys = {

	startAttack = function()
		if keneanung.bashing.attacking > 0 then
			enableTrigger(keneanung.bashing.systems.wundersys.queueTrigger)
			local command
			if keneanung.bashing.configuration[class].attackcommand:find("&tar") then
				command = keneanung.bashing.configuration[class].attackcommand
			else
				command = keneanung.bashing.configuration[class].attackcommand .. " &tar"
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
		if keneanung.bashing.configuration[class].autoraze then
			local command
			if keneanung.bashing.configuration[class].razecommand:find("&tar") then
				command = keneanung.bashing.configuration[class].razecommand
			else
				command = keneanung.bashing.configuration[class].razecommand .. " &tar"
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
		if keneanung.bashing.configuration[class].razecommand:find("&tar") then
			razecommand = keneanung.bashing.configuration[class].razecommand
		else
			razecommand = keneanung.bashing.configuration[class].razecommand .. " &tar"
		end
		if command == razecommand then
			keneanung.bashing.shield = false
		end
	end,

	pause = function()
		keneanung.bashing.systems.wundersys.stopAttack()
	end,

	unpause = function()
		keneanung.bashing.systems.wundersys.startAttack()
	end
}

keneanung.bashing.systems.none = {

	startAttack = function()
		if keneanung.bashing.attacking > 0 then
			enableTrigger(keneanung.bashing.systems.none.queueTrigger)
			send("queue add eqbal keneanungki", false)
		end
	end,

	stopAttack = function()
		disableTrigger(keneanung.bashing.systems.none.queueTrigger)
		send("cq all")
	end,

	flee = function()
		keneanung.bashing.systems.none.stopAttack()
		send("queue prepend eqbal " .. keneanung.bashing.fleeDirection)
	end,

	warnFlee = function(avg)
		echo("Better run or get ready to die!")
	end,

	notifyFlee = function(avg)
		echo("Running as you have not enough health left.")
	end,

	handleShield = function()
		keneanung.bashing.shield = true
		if keneanung.bashing.configuration[class].autoraze then
			local command
			send("queue prepend eqbal keneanungra", false)
		end
	end,

	brokeShield = function()
		send("cq all")
		send("queue add eqbal keneanungki", false)
	end,

	setup = function()
		keneanung.bashing.systems.none.queueTrigger = tempRegexTrigger("^\\[System\\]: Running queued eqbal command: (KENEANUNGKI|KENEANUNGRA)$",
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
				if matches[2] == "KENEANUNGKI" then
					send("queue add eqbal keneanungki", false)
				else
					keneanung.bashing.shield = false
				end
			end
			]])
		disableTrigger(keneanung.bashing.systems.none.queueTrigger)
	end,

	teardown = function()
		if keneanung.bashing.systems.none.queueTrigger then
			killTrigger(keneanung.bashing.systems.none.queueTrigger)
		end
	end,

	pause = function()
		disableTrigger(keneanung.bashing.systems.none.queueTrigger)
	end,

	unpause = function()
		keneanung.bashing.systems.none.startAttack()
	end

}

local function sendRageAttack(attack)
	debugMessage("sending rage attack", attack)
	send(attack:format(keneanung.bashing.targetList[keneanung.bashing.attacking].id), false)
	keneanung.bashing.usedRageAttack = true
	tempTimer(1, "keneanung.bashing.usedRageAttack = false")
end

local function rageRazeFunction()
	if keneanung.bashing.shield then
		if keneanung.bashing.configuration[class].autorageraze and keneanung.bashing.rageAvailable(3) then
			send(battlerageSkills[3].command:format(keneanung.bashing.targetList[keneanung.bashing.attacking].id), false)
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
			rageraze = keneanung.bashing.configuration[class].autorageraze,
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
			rageraze = keneanung.bashing.configuration[class].autorageraze,
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
		else
			return keneanung.bashing.systems.none
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
			keneanung.bashing.configuration[class].attackcommand
		),
		"clearCmdLine() appendCmdLine('kconfig bashing attackcommand ')",
		"Set attack."
	)

	kecho(
		string.format(
			"Autoraze is <red>%s<reset>",
			keneanung.bashing.configuration[class].autoraze and "on" or "off"
		),
		"keneanung.bashing.toggle('autoraze', 'Autorazing')",
		string.format(
			"Turn autorazing %s",
			keneanung.bashing.configuration[class].autoraze and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Special attack on shielding is set to <red>%s<reset>",
			keneanung.bashing.configuration[class].razecommand
		),
		"clearCmdLine() appendCmdLine('kconfig bashing razecommand ')",
		"Set attack to raze shields."
	)

	kecho(
		string.format(
			"Razing shields with rage is <red>%s<reset>",
			keneanung.bashing.configuration[class].autorageraze and "on" or "off"
		),
		"keneanung.bashing.toggle('autorageraze', 'Autorazing with rage')",
		string.format(
			"Turn autorazing with rage %s",
			keneanung.bashing.configuration[class].autorageraze and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Currently using this battlerage strategy: <red>%s<reset>",
			keneanung.bashing.configuration[class].rageStrat
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

	kecho(
		string.format(
			"Considering loyals for fallback targets is <red>%s<reset>",
			keneanung.bashing.configuration.targetLoyals and "on" or "off"
		),
		"keneanung.bashing.toggle('targetLoyals', 'Falling back to loyal targets')",
		string.format(
			"Turn considering loyals for fallback targets %s",
			keneanung.bashing.configuration.targetLoyals and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Manual targetting is <red>%s<reset>",
			keneanung.bashing.configuration.manualTargetting and "on" or "off"
		),
		"keneanung.bashing.toggle('manualTargetting', 'Manual targetting')",
		string.format(
			"Turn manual targetting %s",
			keneanung.bashing.configuration.manualTargetting and "off" or "on"
		)
	)

	kecho(
		string.format(
			"Waiting for <red>%s<reset> seconds for a new target before stopping, if attacking manually",
			keneanung.bashing.configuration.waitForManualTarget
		),
		"clearCmdLine() appendCmdLine('kconfig bashing waitfortarget ')",
		"Set time to wait for a target."
	)

	kecho(
		string.format(
			"Battlerage skills identified (<red>reset<reset>): " .. knownBattlerageSkillList()
		),
		"keneanung.bashing.configuration.requestBattlerageSkills()",
		"Request and parse battlerage skills again."
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
	local toPrint
	if what == "autoraze" or what == "autorageraze" then
		keneanung.bashing.configuration[class][what] = not keneanung.bashing.configuration[class][what]
		toPrint = keneanung.bashing.configuration[class][what] and "enabled" or "disabled"
	else
		keneanung.bashing.configuration[what] = not keneanung.bashing.configuration[what]
		toPrint = keneanung.bashing.configuration[what] and "enabled" or "disabled"
	end
	kecho(print .. " <red>" .. toPrint .. "\n" )
	keneanung.bashing.save()
end

keneanung.bashing.shielded = function(what)
	if keneanung.bashing.attacking > 0 and what == keneanung.bashing.targetList[keneanung.bashing.attacking].name then
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

keneanung.bashing.attackButton = function(toggle)
    if toggle == nil then
		if keneanung.bashing.attacking == 0 then
			if keneanung.bashing.setTarget() then
				startAttack()
				kecho("Nothing will stand in our way.\n")
			else
				kecho("Nothing to target, boss.\n")
			end
		else
			keneanung.bashing.clearTarget()
			stopAttack()
			kecho("Lets save them for later.\n")
		end
	elseif toggle then
		if keneanung.bashing.setTarget() then
			startAttack()
			kecho("Nothing will stand in our way.\n")
        else
            kecho("Nothing to target, boss.\n")
        end	
	else
		keneanung.bashing.clearTarget()
		stopAttack()
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

keneanung.bashing.setWaitForTarget = function(amount)
	keneanung.bashing.configuration.waitForManualTarget = tonumber(amount) or 2
	kecho("Waiting <red>" .. keneanung.bashing.configuration.waitForManualTarget .. "<reset> seconds for a new target\n" )
	keneanung.bashing.save()
end

keneanung.bashing.nextAttack = function()
	if keneanung.bashing.configuration.enabled == false then
		return false
	end

	if keneanung.bashing.usedBalanceAttack then
		return true
	end

	if #keneanung.bashing.pausingAfflictions > 0 then
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

			local attack = (keneanung.bashing.shield and keneanung.bashing.configuration[class].autoraze) and "keneanungra" or "keneanungki"
			send(attack, false)
			keneanung.bashing.shield = false
			keneanung.bashing.usedBalanceAttack = true
			tempTimer( 0.5, "keneanung.bashing.usedBalanceAttack = false")
			return true

		end

	end

	keneanung.bashing.clearTarget()
	stopAttack()
	return false

end

local roomItemCallbackWorker = function(event)

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
		if item.attrib and item.attrib:find("m") and not item.attrib:find("d") then
			keneanung.bashing.seenDenizen(item.id, item.name)
			item = keneanung.bashing.getTargetObject(item.id)
			if not keneanung.bashing.configuration.manualTargetting then
				keneanung.bashing.addTarget(item)
			end
		end
	end

	if(event == "gmcp.Char.Items.List") then

		if not keneanung.bashing.configuration.manualTargetting then
		--restore targets we had when we were in the room last
			local storedTargets = roomTargetStore[gmcp.Room.Info.num]

			if storedTargets then
				keneanung.bashing.targetList = storedTargets.targetList
			end

			local targetList = {}
			-- make sure our targets stay at the same place!
			for index, targ in ipairs(keneanung.bashing.targetList) do
				-- search if that target possibly left the room
				local found = false
				for _, item in ipairs(gmcp.Char.Items.List.items) do
					if item.id == targ.id then
						found = true
						break
					end
				end
				-- still there? Add it in the old place
				if found then
					targetList[#targetList + 1] = targ
				end
			end
			keneanung.bashing.targetList = targetList
		end

		keneanung.bashing.room = {}
		for _, item in ipairs(gmcp.Char.Items.List.items) do
			keneanung.bashing.room[#keneanung.bashing.room + 1] = item
			if item.attrib and item.attrib:find("m") and not item.attrib:find("d") then
				keneanung.bashing.seenDenizen(item.id, item.name)
				item = keneanung.bashing.getTargetObject(item.id)
				if not keneanung.bashing.configuration.manualTargetting then
					keneanung.bashing.addTarget(item)
				end
			end
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

keneanung.bashing.roomItemCallback = function(event)
	if event == "gmcp.Char.Items.Add" or event == "gmcp.Char.Items.Remove" then
		roomItemCallbackWorker(event)
	end
end

keneanung.bashing.sysDataSendRequestCallback = function(_, data)
	debugMessage("data gets sent", {data = data})
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

		table.insert(targets, insertAt, item)

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
		if keneanung.bashing.attacking == 0 and keneanung.bashing.configuration.manualTargetting then
			waitingForManualTarget = true
			waitingForManualTargetTimer = tempTimer(keneanung.bashing.configuration.waitForManualTarget, function() waitingForManualTarget = false end)
		end
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

	if not keneanung.bashing.configuration.manualTargetting then
		roomTargetStore[keneanung.bashing.lastRoom] = {
			targetList = keneanung.bashing.targetList,
		}
	end

	keneanung.bashing.damage = 0
	keneanung.bashing.healing = 0
	keneanung.bashing.attacks = 0
	keneanung.bashing.lastHealth = gmcp.Char.Vitals.hp * 1
	keneanung.bashing.shield = false
	if keneanung.bashing.attacking > 0 then
		keneanung.bashing.clearTarget()
		stopAttack()
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

	roomItemCallbackWorker("gmcp.Char.Items.List")	-- update the room item list now, because now we know if we changed the area.
							-- also be optimistic that there is no other items list in between
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

	keneanung.bashing.battlerage[keneanung.bashing.configuration[class].rageStrat](rage, battlerageSkills)

end

keneanung.bashing.buttonActionsCallback = function()
	keneanung.bashing.battlerage[keneanung.bashing.configuration[class].rageStrat](rage, battlerageSkills)
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
		keneanung.bashing.configuration.requestBattlerageSkills() -- rerequest attainment abilities
		migrateTo1Point8()
		if not keneanung.bashing.configuration[class] then
			local newClassConfig = {}
			newClassConfig.autoraze = false
			newClassConfig.razecommand = "none"
			newClassConfig.attackcommand = "kill"
			newClassConfig.rageStrat = "simple"
			keneanung.bashing.configuration[class] = newClassConfig
			kecho("Seen new class " .. class .. ". Default config set.")
		end
		keneanung.bashing.setAlias("attackcommand")
		keneanung.bashing.setAlias("razecommand")
	end

	debugMessage("Going to calculate gold gains", { lastGoldChange = lastGoldChange, lastGold = lastGold } )

	local goldNumber = tonumber(gmcp.Char.Status.gold)
	local goldChange = goldNumber - (lastGold or 0)

	debugMessage("Got new gold numbers", { goldChange = goldChange, goldNumber = goldNumber } )

	local lifetimeGains = keneanung.bashing.configuration.lifetimeGains

	if lastGoldChange ~= nil then -- On login, skip this

		if goldChange + lastGoldChange ~= 0 and goldChange > 0 then	-- We only want to count
										-- real changes (not
			sessionGains.gold = sessionGains.gold + goldChange	-- taking from pack) and
			tripGains.gold = tripGains.gold + goldChange		-- gold gains.
			lifetimeGains.gold = lifetimeGains.gold + goldChange

		end

	end

	lastGoldChange = goldChange
	lastGold = goldNumber

	local newXp = gmcp.Char.Status.level:match("^(%d+)") * 100 + gmcp.Char.Status.xp:match("(.+)%%")

	debugMessage("Calculating experience gain", { lastXp = lastXp, newXp = newXp })

	if lastXp ~= nil then

		sessionGains.experience = sessionGains.experience + newXp - lastXp
		tripGains.experience = tripGains.experience + newXp - lastXp
		lifetimeGains.experience = lifetimeGains.experience + newXp - lastXp

	end

	lastXp = newXp
end

local proneAfflictions = {
	"prone",
	"stun",
	"paralysis",
	"entangled",
	"webbed",
	"transfixation",
	"impaled",
	"bound",
	"aeon",
}

keneanung.bashing.pauseOnAffliction = function(affliction)
	affliction = affliction:lower()
	if table.contains(proneAfflictions, affliction) then
		local pAffs = keneanung.bashing.pausingAfflictions
		if not table.contains(pAffs, affliction) then
			pAffs[#pAffs + 1] = affliction
			local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
			if system.pause then
				system.pause()
			end
		end
	end
end

keneanung.bashing.unpauseOnHealing = function(affliction)
	affliction = affliction:lower()
	if table.contains(proneAfflictions, affliction) then
		local pAffs = keneanung.bashing.pausingAfflictions
		local index = 0
		for i, aff in ipairs(pAffs) do
			if aff == affliction then
				index = i
				break
			end
		end
		if index > 0 then
			table.remove(pAffs, index)
		end
		if #pAffs == 0 then
			local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
			if system.unpause and keneanung.bashing.attacking > 0 then
				system.unpause()
			end
		end
	end
end

keneanung.bashing.afflictionCallback = function(_, origMessage)
	if origMessage == "gmcp.Char.Afflictions.Add" then
		keneanung.bashing.pauseOnAffliction(gmcp.Char.Afflictions.Add.name)
	elseif origMessage == "gmcp.Char.Afflictions.Remove" then
		keneanung.bashing.unpauseOnHealing(gmcp.Char.Afflictions.Remove[1])
	end
end

keneanung.bashing.setCommand = function(command, what)
	keneanung.bashing.configuration[class][command] = what
	kecho(command .. " is now <red>" .. keneanung.bashing.configuration[class][command] .. "<reset>\n" )
	keneanung.bashing.setAlias(command)
	keneanung.bashing.save()
end

keneanung.bashing.setTarget = function()
	if #keneanung.bashing.targetList == 0 then
		local tar
		local targetSet = false

		if target ~= nil and target ~='' and target:lower() ~= "none" then
			tar = target
		elseif gmcp.Char.Status.target ~= "None" then
			tar = gmcp.Char.Status.target
		end

		debugMessage("set tar", tar)

		if tar ~= nil then

			for _, item in ipairs(keneanung.bashing.room) do
				if item.attrib and item.attrib:find("m") and not item.attrib:find("d") and item.name:lower():find(tar:lower()) then
					if keneanung.bashing.configuration.targetLoyals or not item.attrib:find("x") then
						keneanung.bashing.targetList[#keneanung.bashing.targetList + 1]= {
							id = item.id,
							name = item.name
						}
						targetSet = true
					end
				end
			end
		end
		if not targetSet then
			keneanung.bashing.clearTarget()
			stopAttack()
			return
		end
	end
	if keneanung.bashing.attacking == 0 or keneanung.bashing.targetList[keneanung.bashing.attacking].id ~= gmcp.IRE.Target.Info.id then
		keneanung.bashing.attacking = keneanung.bashing.attacking + 1
	end
	debugMessage("setting target", keneanung.bashing.targetList[keneanung.bashing.attacking])
	sendGMCP('IRE.Target.Set "' .. keneanung.bashing.targetList[keneanung.bashing.attacking].id .. '"')
        return keneanung.bashing.attacking ~= 0
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
	sendGMCP([[Char.Skills.Get {"group":"attainment"}]])
	local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
	system.setup()
	sessionGains.gold = 0
	sessionGains.experience = 0
	lastGoldChange = nil
	lastXpChange = nil
	lastGold = nil
end

keneanung.bashing.setAlias = function(command)
	local attackCommand
	if keneanung.bashing.configuration[class][command]:find("&tar") then
		attackCommand = keneanung.bashing.configuration[class][command]
	else
		attackCommand = keneanung.bashing.configuration[class][command] .. " &tar"
	end
	send(string.format("setalias %s %s", aliases[command], attackCommand), false)
end

keneanung.bashing.setSystem = function(systemName)

	if not systemName then
		kecho("The following systems are known:")
		for name, _ in pairs(keneanung.bashing.systems) do
			kecho("   " .. name, "keneanung.bashing.setSystem('" .. name .. "')", "Set '" .. name .. "' as queueing system")
		end
		kecho("   auto", "keneanung.bashing.setSystem('auto')", "Set 'auto' as queueing system")
		echo("\n")
		return
	end

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

	if not strategyName then
		kecho("The following rage strategies are known:")
		for name, _ in pairs(keneanung.bashing.battlerage) do
			kecho("   " .. name, "keneanung.bashing.setRageStrat('" .. name .. "')", "Set '" .. name .. "' as battlerage strategy")
		end
		echo("\n")
		return
	end

	if not keneanung.bashing.battlerage[strategyName] then
		kecho("<orange>Battlerage strategy not changed as '" .. strategyName .. "' is unknown.")
		return
	end
	keneanung.bashing.configuration[class].rageStrat = strategyName
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

keneanung.bashing.addDenizenAffliction = function(denizen, affliction, own)
	debugMessage("New denizen affliction.", { denizen = denizen, affliction = affliction, own = own })

	local affObject = afflictions[affliction]
	debugMessage("associated affliction object", affObject)
	if not affObject then
		kecho("Affliction '<red>" .. affliction .. "<reset>' is not a known denizen affliction.")
		return
	end

	local denizenObject = keneanung.bashing.getTargetObject(denizen)
	debugMessage("associated denizen object from direct access", denizenObject)
	if not denizenObject then
		kecho("Denizen '<red>" .. denizen .. "<reset>' not in list of targets. Fallback is not yet implemented.")
		return
	end

	local isTarget = (keneanung.bashing.targetList[keneanung.bashing.attacking].id == denizenObject.id)

	denizenObject.affs[affliction] = tempTimer(affObject.timer,
		string.format("keneanung.bashing.removeDenizenAffliction('%s', '%s', %s)", denizenObject.id, affliction, own and "true" or "false"))

	kecho(string.format("<%s>%s%s<reset> <green>gained<reset> <%s>%s<reset>", isTarget and "OrangeRed" or "yellow",
		denizenObject.name, isTarget and " (your target)" or "", affObject.colour, affliction))
	if own then
		raiseEvent("keneanung.bashing.afflictionGained", denizenObject.id, affliction)
	end
end

keneanung.bashing.removeDenizenAffliction = function(denizen, affliction, own)
	debugMessage("Remove denizen affliction.", { denizen = denizen, affliction = affliction, own = own })

	local affObject = afflictions[affliction]
	debugMessage("associated affliction object", affObject)
	if not affObject then
		kecho("Affliction '<red>" .. affliction .. "<reset>' is not a known denizen affliction.")
		return
	end

	local denizenObject = directTargetAccess[denizen]
	debugMessage("associated denizen object from direct access", denizenObject)
	if not denizenObject then
		return
	end

	local isTarget = (keneanung.bashing.targetList[keneanung.bashing.attacking].id == denizenObject.id)

	killTimer(denizenObject.affs[affliction])
	kecho(string.format("<%s>%s%s<reset> <red>lost<reset> <%s>%s<reset>",
		isTarget and "OrangeRed" or "yellow", denizenObject.name, isTarget and " (your target)" or "", affObject.colour, affliction))
	if own then
		raiseEvent("keneanung.bashing.afflictionLost", denizenObject.id, affliction)
	end
	denizenObject.affs[affliction] = nil
end

keneanung.bashing.getAfflictions = function(denizen)
	debugMessage("Returnung denizen affliction.", { denizen = denizen })

	local denizenObject = directTargetAccess[denizen]
	debugMessage("associated denizen object from direct access", denizenObject)
	if not denizenObject then
		return {}
	end

	local ret = {}
	for aff, _ in pairs(denizenObject.affs) do
		ret[#ret + 1] = aff
	end

	return ret
end

keneanung.bashing.hasAffliction = function(denizen, affliction)
	debugMessage("Checking for denizen affliction.", { denizen = denizen, affliction = affliction })

	local denizenObject = directTargetAccess[denizen]
	debugMessage("associated denizen object from direct access", denizenObject)
	if not denizenObject then
		return false
	end

	return denizenObject.affs[affliction] ~= nil
end

keneanung.bashing.handleSkillList = function()
	local skillList = gmcp.Char.Skills.List
	if skillList.group ~= "attainment" then return end

	for _, skill in ipairs(skillList.list) do
		if not table.contains(nonBattlerageAttainmentSkills, skill) then
			requestSkillDetails[#requestSkillDetails + 1] = skill
		end
	end
	battlerageSkills = {}
	requestAllSkillDetails()
end

keneanung.bashing.handleSkillInfo = function()
	local skillInfo = gmcp.Char.Skills.Info
	if skillInfo.group ~= "attainment" then return end

	local cooldown = tonumber(skillInfo.info:match("(%d+\.%d+) seconds"))
	local rage = tonumber(skillInfo.info:match("(%d+) rage"))
	local command = skillInfo.info:match("Syntax:\n(.-)\n"):gsub("<target>", "%%s")
	local affliction = skillInfo.info:match("Gives denizen affliction: (%w+)")
	local affsUsed = {skillInfo.info:match("Uses denizen afflictions: (%w+) or (%w+)")}
	for ind, aff in ipairs(affsUsed) do
		affsUsed[ind] = aff:lower()
	end
	local skillKnown = skillInfo.info:find("*** You have not yet learned this ability ***", 1, true) == nil

	local rageObject = {
		cooldown = cooldown,
		rage = rage,
		command = command,
		affliction = affliction and affliction:lower(),
		affsUsed = affsUsed,
		name = skillInfo.skill:lower(),
		skillKnown = skillKnown
	}

	if #battlerageSkills == 0 or skillInfo.skill:lower() ~= battlerageSkills[#battlerageSkills].name then
		if battlerageSkills[skillInfo.skill] then
			battlerageSkills[skillInfo.skill] = rageObject
			for index, oldObject in ipairs(battlerageSkills) do
				if oldObject.name == rageObject.name then
					battlerageSkills[index] = rageObject
					break
				end
			end
			debugMessage("Updated skill " .. skillInfo.skill .. ", complete list is here ", battlerageSkills)
		else
			battlerageSkills[skillInfo.skill] = rageObject
			battlerageSkills[#battlerageSkills + 1] = rageObject
			debugMessage("added new battlerage skill complete list is here ", battlerageSkills)
			if #battlerageSkills == 6 then
				sortDepthswalkerBattlerage()
				kecho("Finished parsing battlerage skills.\n")
			end
		end
	else
		debugMessage("got double battlerage skill")
	end
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

keneanung.bashing.printGains = function(which)
	local gainsTable
	if which == "lifetime" then
		gainsTable = keneanung.bashing.configuration.lifetimeGains
	elseif which == "session" then
		gainsTable = sessionGains
	elseif which == "trip" then
		gainsTable = tripGains
	else
		kecho(string.format("Gains for the timespan '<red>%s<reset>' are not tracked.", which))
		return
	end

	local levels, percent = math.modf(gainsTable.experience / 100)
	percent = percent * 100
	kecho(string.format("You gained <red>%d<reset> levels, <red>%.1f%%<reset> towards the next level and <red>%d<reset> gold during the period '<red>%s<reset>'.", levels, percent, gainsTable.gold, which))
	if gainsTable.stopwatch then
		local time = getStopWatchTime(gainsTable.stopwatch)
		kecho(string.format("The period was <red>%d<reset>h <red>%d<reset>min and <red>%.3f<reset> sec long.", math.floor(time / 3600), math.floor( math.mod(time, 3600) / 60), math.mod(time, 60)))
	end
end

keneanung.bashing.startHuntingTrip = function()
	if not tripGains.stopwatch then
		tripGains = { gold = 0, experience = 0, stopwatch = createStopWatch() }
		startStopWatch(tripGains.stopwatch)
		kecho("Started new hunting trip. Enjoy and be careful.")
	else
		kecho("Ugh- Finish the running trip before starting a new one?")
	end
end

keneanung.bashing.stopHuntingTrip = function()
	if tripGains.stopwatch then
		kecho("Stopped hunting trip. I hope you had fun.")
		keneanung.bashing.printGains("trip")
		stopStopWatch(tripGains.stopwatch)
		tripGains.stopwatch = nil
	else
		kecho("You are not hunting or didn't tell me you did. Can't stop anything.")
	end
end

keneanung.bashing.seenDenizen = function(id, name)
	if denizenCache[id] then
		local timer = denizenCache[id].expireTimer
		killTimer(timer)
		timer = tempTimer(10 * 60, "keneanung.bashing.unseenDenizen('" .. id .. "')")
		denizenCache[id].expireTimer = timer
	else
		local cacheObject = { name = name }
		cacheObject.expireTimer = tempTimer(10 * 60, "keneanung.bashing.unseenDenizen('" .. id .. "')")
		denizenCache[id] = cacheObject
	end
end

keneanung.bashing.unseenDenizen = function(id)
	if denizenCache[id] then
		killTimer(denizenCache[id].expireTimer)
		denizenCache[id] = nil
	end
	if directTargetAccess[id] then
		directTargetAccess[id] = nil
	end
end

keneanung.bashing.getDenizenName = function(id)
	return denizenCache[id] and denizenCache[id].name or "unknown"
end

keneanung.bashing.getTargetObject = function(id)
	if not tonumber(id) then
		kecho("You are trying to access the denizen with ID <red>" .. id .. "<reset> which is not a numerical ID.")
		return
	end
	local result = directTargetAccess[tostring(id)]
	if not result then
		result = { id = id, name = keneanung.bashing.getDenizenName(id), affs = {} }
		directTargetAccess[tostring(id)] = result
	end
	return result
end

local doImport = function(importTable)
	--Allow us to strip a full config file down to just the priorities
	importTable = importTable.priorities or importTable
	--do the import
	for area,_ in pairs(importTable) do
		if #importTable[area] > 0 then
			keneanung.bashing.configuration.priorities[area] = keneanung.bashing.configuration.priorities[area] or {}
		end
		for _, denizenString in pairs(importTable[area]) do
			if not table.contains(keneanung.bashing.configuration.priorities[area],denizenString) then
				table.insert(keneanung.bashing.configuration.priorities[area], denizenString)
			end
		end
	end
end

keneanung.bashing.guhemImport = function()
	doImport(huntVar.userAreaList)
end

keneanung.bashing.export = function()
	local directory = invokeFileDialog(false, "Which file do you want to export your priorities to?")
	if directory ~= "" then -- If a folder was provided
		table.save(directory .. "/Bashing-Export.lua", keneanung.bashing.configuration.priorities) -- Exporting to folder specified
		kecho("Have exported priorities to <red>" .. path .. "/Bashing-Export.lua<reset>") -- Messaging user
	end
end

keneanung.bashing.import = function()
	local path = invokeFileDialog(true, "Which file do you want to add?") -- Requesting the specific file to be imported
	if path ~= "" then -- Making sure that the file was specified
		local importTable = {}
		table.load(path, importTable)
		doImport(importTable)
		kecho("Import Completed")
	end --if
end

keneanung.bashing.manuallyTarget = function(what)
	if not keneanung.bashing.configuration.manualTargetting then return end
	local item = keneanung.bashing.getTargetObject(what)
	if not item then return end
	keneanung.bashing.targetList = { item }
	sendGMCP('IRE.Target.Set "' .. item.id .. '"')
	raiseEvent("keneanung.bashing.targetList.changed")
	raiseEvent("keneanung.bashing.targetList.firstChanged", keneanung.bashing.targetList[1].id)
	if waitingForManualTargetTimer then killTimer(waitingForManualTargetTimer) end
	if waitingForManualTarget then
		keneanung.bashing.setTarget()
		startAttack()
	end
end

keneanung.bashing.load()
for _, file in ipairs(keneanung.bashing.configuration.filesToLoad) do
	dofile(file)
end
tempTimer(0, [[raiseEvent("keneanung.bashing.loaded")]])
