keneanung.bashing.configuration.enabled = false
keneanung.bashing.attacking = 0
keneanung.bashing.roomDamage = 0
keneanung.bashing.attacks = 0
keneanung.bashing.configuration.warning = 500
keneanung.bashing.configuration.fleeing = 300
keneanung.bashing.configuration.autoflee = true
keneanung.bashing.configuration.autoraze = false
keneanung.bashing.configuration.razecommand = "none"

keneanung.bashing.addPossibleTarget = function(targetName)

	local prios = keneanung.bashing.configuration.priorities
	local area = gmcp.Room.Info.area

	if prios[area] == nil then
		prios[area] = {}
		cecho("\n<green>keneanung<reset>: Added the new area <red>" .. area .. "<reset> to the configuration.")
	end

	if not table.contains(prios[area], targetName) then
		table.insert(prios[area], targetName)
		cecho("\n<green>keneanung<reset>: Added the new possible target <red>" .. targetName .. "<reset> to the end of the priority list.")
	end

	keneanung.bashing.configuration.priorities = prios

	keneanung.bashing.save()

end

keneanung.bashing.showAreas = function()

	local prios = keneanung.bashing.configuration.priorities

	cecho("<green>keneanung<reset>: Which area would you like to configure:\n")
	for area, _ in pairs(prios) do
     echo("   (")
     setUnderline(true)
     fg("orange")
     echoLink(string.format("%s", area),[[keneanung.bashing.managePrios("]]..area..[[")]],"Show priority list for '" .. area .."",true)
     resetFormat()
     echo(")\n")
	end
end

keneanung.bashing.managePrios = function(area)
	local prios = keneanung.bashing.configuration.priorities[area]

	if prios == nil then
		cecho("<green>keneanung<reset>: No targets for <red>" .. area .. "<reset> found yet!\n")
		return
	end

	cecho("<green>keneanung<reset>: Possible targets for <red>" .. area .. "<reset>:\n")
	for num, item in ipairs(prios) do
		echo("     ")
		fg("antique_white")
		echoLink("(", [[keneanung.bashing.shuffleUp("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step up.", true)
		fg("light_blue")
		echoLink("^^", [[keneanung.bashing.shuffleUp("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step up.", true)
		fg("antique_white")
		echoLink(")", [[keneanung.bashing.shuffleUp("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step up.", true)
		echo(" ")
		echoLink("(", [[keneanung.bashing.shuffleDown("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step down.", true)
		fg("red")
		echoLink("vv", [[keneanung.bashing.shuffleDown("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step down.", true)
		fg("antique_white")
		echoLink(")", [[keneanung.bashing.shuffleDown("]]..area..[[", ]] .. num .. [[)]], "Shuffle " .. item .. " one step down.", true)
		echo(" ")
		echoLink("(", [[keneanung.bashing.delete("]]..area..[[", ]] .. num .. [[)]], "Delete " .. item .. " from list.", true)
		fg("gold")
		echoLink("DD", [[keneanung.bashing.delete("]]..area..[[", ]] .. num .. [[)]], "Delete " .. item .. " from list.", true)
		fg("antique_white")
		echoLink(")", [[keneanung.bashing.delete("]]..area..[[", ]] .. num .. [[)]], "Delete " .. item .. " from list.", true)
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
	cecho("<green>keneanung<reset>: Bashing is ")
	fg("red")
	echoLink(keneanung.bashing.configuration.enabled and "on" or "off", "keneanung.bashing.toggle('enabled', 'Bashing')", "Turn bashing " .. (keneanung.bashing.configuration.enabled and "off" or "on"), true)
	resetFormat()
	echo("\n")
	cecho("<green>keneanung<reset>: Automatic fleeing is ")
	fg("red")
	echoLink(keneanung.bashing.configuration.autoflee and "on" or "off", "keneanung.bashing.toggle('autoflee', 'Fleeing')", "Turn fleeing " .. (keneanung.bashing.configuration.autoflee and "off" or "on"), true)
	resetFormat()
	echo("\n")
	cecho("<green>keneanung<reset>: Warning at a security threshhold of ")
	fg("red")
	echoLink(keneanung.bashing.configuration.warning, "clearCmdLine() appendCmdLine('kconfig bashing warnat ')", "Set warn threshold.", true)
	resetFormat()
	echo(" health\n" )
	cecho("<green>keneanung<reset>: Fleeing at a security threshhold of ")
	fg("red")
	echoLink(keneanung.bashing.configuration.fleeing, "clearCmdLine() appendCmdLine('kconfig bashing fleeat ')", "Set flee threshold.", true)
	resetFormat()
	echo(" health\n" )
	cecho("<green>keneanung<reset>: Autoraze is ")
	fg("red")
	echoLink(keneanung.bashing.configuration.autoraze and "on" or "off", "keneanung.bashing.toggle('autoraze', 'Autorazing')", "Turn autorazing " .. (keneanung.bashing.configuration.autoraze and "off" or "on"), true)
	resetFormat()
	echo("\n")
	cecho("<green>keneanung<reset>: Special attack on shielding is set to ")
	fg("red")
	echoLink(keneanung.bashing.configuration.razecommand, "clearCmdLine() appendCmdLine('kconfig bashing razecommand ')", "Set attack to raze shields.", true)
	resetFormat()
	echo("\n")
end

keneanung.bashing.toggle = function(what, print)
	keneanung.bashing.configuration[what] = not keneanung.bashing.configuration[what]
	cecho("<green>keneanung<reset>: " .. print .. " <red>" .. (keneanung.bashing.configuration[what] and "enabled" or "disabled") .. "\n" )
	keneanung.bashing.save()
end

keneanung.bashing.shielded = function(what)
	if what == keneanung.bashing.targetList[1].name then
		keneanung.bashing.shield = true
	end
end

keneanung.bashing.flee = function()
	svo.dofreefirst(keneanung.bashing.fleeDirection)
	svo.removebalanceful("do next attack")
	keneanung.bashing.attacking = 0
	cecho("<green>keneanung<reset>: New order. Tactical retreat.\n")
end

keneanung.bashing.attackButton = function()
	if keneanung.bashing.attacking == 0 then
		svo.addbalanceful("do next attack", keneanung.bashing.nextAttack)
		svo.donext()
		cecho("<green>keneanung<reset>: Nothing will stand in our way.\n")
	else
		svo.removebalanceful("do next attack")
		keneanung.bashing.attacking = 0
		cecho("<green>keneanung<reset>: Lets save them for later.\n")
	end
end

keneanung.bashing.setFlee = function(where)
	keneanung.bashing.fleeDirection = where
	cecho("<green>keneanung<reset>: Fleeing to the <red>" .. keneanung.bashing.fleeDirection .. "\n" )
end

keneanung.bashing.setThreshold = function(newValue, what)
	keneanung.bashing.configuration[what] = matches[2] * 1
	cecho("<green>keneanung<reset>: "..what:title().." with a security threshhold of <red>" .. keneanung.bashing.configuration[what] .. "<reset> health\n" )
	keneanung.bashing.save()
end

keneanung.bashing.nextAttack = function()
	if keneanung.bashing.configuration.enabled == false then
		return false
	end

	keneanung.bashing.attacks = keneanung.bashing.attacks + 1

	if #keneanung.bashing.targetList > 0 then

		local avg = keneanung.bashing.damage / keneanung.bashing.attacks

		if avg > gmcp.Char.Vitals.hp - keneanung.bashing.configuration.fleeing and keneanung.bashing.configuration.autoflee then

			svo.givewarning_multi({initialmsg = "Running as you have not enough health left. (" .. avg .. " vs " .. gmcp.Char.Vitals.hp - keneanung.bashing.configuration.fleeing .. ")"})

			send(keneanung.bashing.fleeDirection)

		else
			if avg > gmcp.Char.Vitals.hp - keneanung.bashing.configuration.warning then

				svo.givewarning_multi({initialmsg = "You are about to die... Better run or get ready to die! (" .. avg .. " vs " .. (gmcp.Char.Vitals.hp - keneanung.bashing.configuration.fleeing) .. ")"})

			end
		
			local attack = (keneanung.bashing.shield and keneanung.bashing.configuration.autoraze) and keneanung.bashing.configuration.razecommand or "kill"
			send(attack .. " " .. keneanung.bashing.targetList[1].id)
			keneanung.bashing.attacking = 1
			keneanung.bashing.shield = false
			return true

		end

	end

	svo.removebalanceful("do next attack")
	keneanung.bashing.attacking = 0
	return false

end

keneanung.bashing.roomItemCallback = function(event)

	if gmcp.Char.Items[event:match("%w+$")].location ~= "room" or keneanung.bashing.configuration.enabled == false then
		return
	end

	local before = keneanung.bashing.idOnly(keneanung.bashing.targetList)

	if(event == "gmcp.Char.Items.Add") then
		keneanung.bashing.addTarget(gmcp.Char.Items.Add.item)
	end

	if(event == "gmcp.Char.Items.List") then
		keneanung.bashing.targetList = {}
		for _, item in ipairs(gmcp.Char.Items.List.items) do
			keneanung.bashing.addTarget(item)
		end
	end

	if(event == "gmcp.Char.Items.Remove") then
		keneanung.bashing.removeTarget(gmcp.Char.Items.Remove.item)
	end

	local after = keneanung.bashing.idOnly(keneanung.bashing.targetList)

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
		if value ~= list1[num] then return true end
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

	if #targets == 0 then
		table.insert(targets, { id = item.id, name = item.name } )
	else

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
         elseif targetPrio < existingPrio then
            iEnd = iMid - 1
         else
            iStart = iMid + 1
         end

      end

		if not found then
			insertAt = iStart
		end

		if insertAt <= keneanung.bashing.attacking then
			insertAt = keneanung.bashing.attacking + 1
		end

		table.insert(targets, insertAt, { id = item.id, name = item.name })

	end

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
		end
	end

	keneanung.bashing.targetList = targets

end

keneanung.bashing.prioListChangedCallback = function()
	cecho("\n<green>keneanung<reset>: Priority list changed to:\n")
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
	keneanung.bashing.attacks = 0
	keneanung.bashing.lastHealth = gmcp.Char.Vitals.hp * 1
	keneanung.bashing.shield = false

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

	if not found then
		cecho("\n<green>keneanung<reset>: <red>WARNING:<reset> No exit to flee found, reusing <red>" .. keneanung.bashing.fleeDirection .. "<reset>.\n")
	end

	keneanung.bashing.lastRoom = gmcp.Room.Info.num
end

keneanung.bashing.vitalsChangeRecord = function()

	if keneanung.bashing.attacking == 0 then return end

	if keneanung.bashing.lastHealth - gmcp.Char.Vitals.hp > 0 then
		keneanung.bashing.damage = keneanung.bashing.damage + keneanung.bashing.lastHealth - gmcp.Char.Vitals.hp
	end

	keneanung.bashing.lastHealth = gmcp.Char.Vitals.hp * 1

end

keneanung.bashing.setRazeCommand = function(what)
	keneanung.bashing.configuration.razecommand = what
	cecho("<green>keneanung<reset>: Razing shields with <red>" .. keneanung.bashing.configuration.razecommand .. "<reset>\n" )
	keneanung.bashing.save()
end

keneanung.bashing.load()
