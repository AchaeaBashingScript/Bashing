A bashing script Achaea
=======================

[![Join the chat at https://gitter.im/AchaeaBashingScript/Bashing](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/AchaeaBashingScript/Bashing?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

What's this?
------------

While bashing (or hunting NPCs) in Achaea is not overly complicated, it is sometimes useful to handle targets in a certain
order instead of going through the seemingly random list from top to bottom. Different types of targets in an area make
bashing even more cumbersome. To avoid having to target specific NPCs by number (which is error prone and slow), this project
was born.

Requirements
------------

- Mudlet
- gmcp enabled
- if you are not using svo, wundersys or stock server side: a queuing system with a
  [custom plugin](#support-for-other-systems)

Downloads and Releases
----------------------

The bashing script can be downloaded on the
[github release page of the project](https://github.com/achaeabashingscript/Bashing/releases).

Stable releases are versioned with the versioning scheme `vXX.XX` where each XX stands for a number. The latest official
stable release has a green tag on the left side.

Releases with an orange tag are pre-releases for testing. *Those are automatically generated and not guaranteed to work.*
Additional to a numeric version number, the versioning scheme contains a short commit hash and a branch name. If you notice a
problem with a pre-release, please include this information in your bug report.

Quickstart
----------

1. Download the Bashing.mpackage
2. Import the package into Mudlet
3. If using svo: Deactivate or delete the keybinding of F2 that comes with svo
4. If not using svof, wundersys or stock server side queuing: [setup the system table](#support-for-other-systems) and configure 
   `kconfig bashing system <name>`
5. Use the alias `kconfig bashing toggle` to enable the script
6. Start killing things. Acceptable targets must be killed at least once in an area to register them with the bashing script.
   The basher will use the "target" variable or the in game target as a fallback, if there is no item in the prio list.
7. Keep bashing away using the F2 keybinding to work yourself down the list.

Priority management
-------------------

New acceptable targets are always added to the end of a priority list of an area. To change this, you will need to change the
order manually.

Use `kconfig bashing prios` to bring up the list of areas with priority lists. You can then click on an area name to bring
the priority list for that area. To filter the list of areas, you can use `kconfig bashing prios <partial area name>`. If
only one match is found, the list for that area is shown instead.

By using `kconfig bashing prios <area name>` or clicking on an area name in the area list, the script will bring up the
priority list for the area. If you are in that area and have one of these denizen in your room, the script will order them
from top to bottom. That means the topmost NPC type has the highest priority and the one at the lower end of the list the
lowest priority.

To change the position of an item in the list, click the `(vv)` and `(^^)` arrows to lower or raise the priority
respectively. You can also click on the `(DD)` to delete that NPC as an acceptable target.

Setting custom attacks
----------------------

The system supports the setting of custom attack command. To do so, use the alias
`kconfig bashing attackcommand <your command>`. You can use the slash (`/`) to separate multiple commands that should be used
at once. For example 2 handed knights might want to use `kconfig bashing attackcommand battlefury focus speed/kill`.

Shield handling
---------------

### Normal attacks ###

For classes with a quick and easy way to handle shielding NPCs, the basher has a very simple way to use it.

First turn the auto raze option on, using the alias `kconfig bashing raze`. This will enable switching the command used when
the denizen you attack shields. Additionally you need to configure the command used for auto razing. That can be done with
`kconfig bashing razecommand <command>`. You may use `/` as a separator for multiple commands. Use `&tar` as the place holder
for the target, if it needs to be somewhere within the command.

Congratulations, you will now raze the shield of NPCs whenever needed.

### Battlerage attacks ###

Each class has a battlerage attack to break denizen shields. The builtin `simple` and `simplereverse` strategies
will use that ability, if needed and configured.

To configure the use of the ability, simple use the alias `kconfig bashing rageraze`. This will toggle the option.
No other setting is needed.

This setting can be used without the normal attack, in combination (it will use the first available one) or the
normal attack without the battlerage ability.

Fleeing
-------

The basher supports 2 ways to flee from dire situations, be it a stronger NPC entering your room, a tell you need to
concentrate to answer or luring NPCs into another room. The basher will always try to recognize the direction you entered a
room from and flee into that direction. *If that exit is not available, it will use the direction it recorded before.* It
will issue a warning in that case. You can use the alias `flee <command>` to set that manually.

The first way is the manual way. Simple press the keybinding `F3` to stop attacking and move ASAP.

The second way is automated and may be activated, if the **average** damage you have taken in this room between 2 attacks is
higher than you have at the next attack with an configurable threshold. The basher will also issue a warning, if average the
damage between 2 attacks is higher than your current health and another threshold. For the configuration see the
[Configuration](#configuration) section.

Support for groups
------------------

The Basher has a generic support for group bashing built in. However since group
communication is very different between different groups, there are no triggers
or party/group calls or custom battlerage strategies included.

This document will list some general things that may be useful to have or do
when hunting with a group.

### Targetting ###

The system supports a manual targetting mode. That means it won't change the
target list in any way. It won't add things, remove them or change its order,
while in manual mode.

That means it's save to add targets in the order as they are called by the party
leader to the list.

To activate that mode, use the alias `kconfig bashing manual` to toggle manual
targetting.

When in manual targetting mode, you can use the
`keneanung.bashing.manuallyTarget()` function to change the target to a denizen
of your choice by giving it a denizen ID to switch to.

If your current target leaves, it will wait for a time (default 2 seconds), for
a new target to continue attacking. If a new target is set within that timeframe
, the basher will continue attacking. You can customize the time with the
command `kconfig bashing waitfortarget <numberofseconds>`.

### Battlerage strategies ###

Depending on the class and composition of the group, it might be useful to
utilize afflictions, defense or critical battlerage abilities. That is possible
through custom battlerage strategies. Please refer to the scripting section
about those.

### Affliction tracking ###

The basher allows for denizen affliction tracking through the functions 
`keneanung.bashing.addDenizenAffliction(id, affName, raiseEvent)` and
`keneanung.bashing.removeDenizenAffliction(id, addName, raiseEvent)`. Those
functions echo the affliction to the user and associate the affliction with the
target. That way you can access the current affliction state of your target with
`keneanung.bashing.targetList[keneanung.bashing.attacking].affs`, of a general
denizen with `keneanung.bashing.getAfflictions(<id>)`, or check a denizen for a
certain affliction with `keneanung.bashing.hasAffliction(<id>, <affname>)`
(for example in the custom battlerage strategy for critical hits).

Configuration
-------------

The current configuration can be shown with the alias `kconfig bashing`. All items in red are clickable and will either
toggle the item or set the alias to the command line, so you only need to add the add the value you want to set.

The basher stores certain settings for each class, so remember to tweak your
configuration when switching to a new one!

### System use ###

The basher uses external systems for queueing and displaying warnings and notifications. It comes with support for 3 possible
systems out of the box and can be extended via plugins. See [the scripting section]](#support-for-other-systems).

Valid out-of-the-box settings are:
- `auto` (default) which tries to find out automatically, which system is available
- `svo` for using the svof system
- `wundersys` for using the wundersys system
- `none` for using stock server side queueing and plain notifications

If you add your own system table, this option becomes available as a setting as well.

### Warn and flee thresholds ###

You can enable and disable automatic fleeing when the health falls below a certain threshold with the
alias `kconfig bashing autoflee` and the configure thresholds with `kconfig bashing fleeat <health amount>` and
`kconfig bashing warnat <health amount>`.

You may specify values as a flat amount, a percentage of the maximum health (ending the config value with a `%`) or as a
multiple of the damage taken in the room (ending the config value with a `d`) as the security threshold (amount of health
left after subtracting the current damage from the current health).

### The battlerage strategies ###

The script comes with three strategies to use battlerage abilities: `none`, `simple` and `simplereverse`. Each one will be
described here.

#### Battlerage strategy `none` ####

This strategy does nothing. You can use it if you want to manually control which ability to use when.

#### Battlerage strategy `simple` ####

This stratey will break denizen shields first, if that is enabled. If it doesn't need to handle shields, the strategy prefers
to use the slower, but higher damage damage battlerage strategy and will use it whenever it is available. If that ability is 
not known or you have enough rage to follow the slow ability immediately with the fast ability, it will do so.

#### Battlerage strategy `simplereverse` ####

This stratey will break denizen shields first, if that is enabled. If it doesn't need to handle shields, it will use the
faster, weaker battlerage ability whenever possible. Is enough battlerage collected to use the slow, powerful ability, it
will use that one as well.

Other interesting features
--------------------------

### Importing of priorities from Guhem's script ###

Around the time when this basher was first developed, another Achaean user
called Guhem published their bashing script. Since that script is not actively
developed anymore, it is possible to import priorities into this script. Use the
alias `kconfig bashing guhemimport` to do so.

### Tracking of experience and gold gains ###

This script tracks all gold (only gains, less accurate than I'd like on the long
run) and experience (gains and losses, relatively accurate) gains in three
different periods: `lifetime`, `session` and `trip`.

The `lifetime` period should track the gains over the time that the script was
installed.

The `session` period should track the gains over the time this mudlet session
was open. When you close mudlet or the profile and reopen it, these figures are
reset.

The `trip` period is started and stopped manually. You can do so with
`ktrip start` and `ktrip stop` respectively. Useful for splitting the gold at
the end of a hunting trip.

Scripting
---------

Some example scripts can be found in the [plugin repository](https://github.com/achaeabashingscript/BashingPlugins).

### Events ###
The script fires a number of events that can be used to extend the bashing script.

The `keneanung.bashing.targetList.changed` event gets raised whenever anything in the list changes. That may be a new target
gets added, a target removed or the list got reordered. To access the current target list, use
`keneanung.bashing.targetList`.

The `keneanung.bashing.targetList.firstChanged` event is raised whenever the first item of the target list changes. That
means a new target is used. This event also gives the new target as argument to the event handlers. To access the first item
of the target list directly, you can access `keneanung.bashing.targetList[1]`.

The `keneanung.bashing.afflictionGained` event is raised, whenever a new
battlerage affliction is registered, where the user is the source. This event can be used
to relay the information to party or group chats without a need for triggers.
The targetted denizen ID and the affliction used are arguments to this event.

The `keneanung.bashing.afflictionLost` event corresponds to the event above, but
is fired when the denizen lost an affliction.

### Plugins ###
Additions to the script can now be loaded in two ways:
- register to the `keneanung.bashing.loaded` event and run your integration logic there. Use this approach if you need to
   load a package/xml due to triggers/aliases/other scripts
- the user can specify lua files that should be run after the bashing script is loaded. These scripts can be anywhere mudlet
   can reach them. The additional files are run using the lua `dofile`.

### Support for other systems ###
A special case of plugins is the support of custom systems.

While two often used systems (svof and wundersys) are supported out of the box by the bashing script, there are a multitude
of other systems (private and public) out there. To allow integration of the bashing script into these systems, an
interface was designed.

To interface the system, create a table with the following structure:

~~~~~~~
{
	startAttack = function()
		-- code that should be run, whenever the user wants to start attacking.
	end,

	stopAttack = function()
		-- code that should be run, whenever the user (or system) wants to stop attacking
	end,

	flee = function()
		-- code that is run when fleeing is needed
	end,

	warnFlee = function(avg)
		-- code that prints a warning at the "warn" threshold. The variable "avg" contains the
		-- average damage taken between attacks
	end,

	notifyFlee = function(avg)
		-- code that prints a warning at the "flee" threshold. The variable "avg" contains the
		-- average damage taken between attacks
	end,

	handleShield = function()
		-- code that is called, whenever the current target uses the shield tattoo
	end,
	
	brokeShield = function()
		-- code that is called whenever the shield got broken. Currently the shield needs to be actively broken
		-- by yourself to get this called.
	end

	setup = function()
		-- code that is run whenever the user connects to Achaea or the user configures the basher
		-- to use this system
	end,

	teardown = function()
		-- code that is run whenever the user switches from this system to another. Should be used
		-- to undo actions of setup()
	end,
}
~~~~~~~

This table can be added to the `keneanung.bashing.systems` table, using your system name as a key. The user must then
configure the basher to use the system by choosing the name *exactly* like the key you used to add the interface table.

Some further hints:
- If your queueing supports running functions instead of sending things directly to the mud, queue the
   `keneanung.bashing.nextAttack()` function and keep similar to the svo implementation
- If your queueing uses the Achaean server side queue, keep close to the WunderSys implementation
- If your queueing is neither of those two possibilities, think about a way you can register attacks. If you have a way, you
   can check the WunderSys implementation for things needed to flee.

### Custom battlerage strategies ###

To use a custom battlerage strategy, you can add a function to the `keneanung.bashing.battlerage` table under any name you
like. This name will be the value you need to set the ragestrat to, when using the strategy. It is called whenever the amount
of battlerage changes or new abilities are available. The function will receive the current accumulated battlerage and a table of battlerage skills.

The battlerage skills table includes every ability twice: Once with its name as key and once via an index. The indexes are
in the following order:

1. Low damage skill
2. First affliction
3. Shieldbreaker
4. High damage skill
5. Conditional damage skill
6. Second affliction

This is the natural order of most classes battlerage skills, Depthswalker being the exception. But even for Depthswalker the
order given above is true. Each skill is an table with the following structure:

~~~~~~~{lua}
rageObject = {
  cooldown = number,                   -- cool down in seconds
  rage = number,                       -- rage used
  command = string,                    -- command to use the ability, placeholder %s where the target should be
  affliction = string,                 -- affliction given, only present, if an affliction is given
  affsUsed = table,                    -- indexed table of afflictions used, only present if this is the conditional damage ability
  name = string,                       -- name of the battlerage skill, all lower case
  skillKnown = boolean                 -- whether the skill is known or not
}
~~~~~~~

The script also provides the `keneanung.bashing.rageAvailable` function which receives a name or number of a battlerage
ability and returns a boolean if that ability is available (enough battlerage and off cooldown).

As an external script,  the `simple` strategy would look similar to this:

~~~~~~~{lua}
keneanung.bashing.battlerage.simple = function(rage, battlerageSkills)
  if keneanung.bashing.attacking == 0 then return end

  local razed = false
  if keneanung.bashing.shield then
    if keneanung.bashing.configuration[class].autorageraze and keneanung.bashing.rageAvailable(3) then
      send(battlerageSkills[3].command:format(keneanung.bashing.targetList[keneanung.bashing.attacking].id), false)
      keneanung.bashing.shield = false
      local system = keneanung.bashing.systems[keneanung.bashing.configuration.system]
      if system.brokeShield then
        system.brokeShield()
      end
      razed = true
    end
  end

  if not razed then
    if keneanung.bashing.rageAvailable(4) then
      send(battlerageSkills[4].command:format(keneanung.bashing.targetList[keneanung.bashing.attacking].id), false)
    elseif keneanung.bashing.rageAvailable(1) and
            ((not battlerageSkills[4].skillKnown) or
              rage >= (battlerageSkills[1].rage + battlerageSkills[4].rage)
	     )
    then
      send(battlerageSkills[1].command:format(keneanung.bashing.targetList[keneanung.bashing.attacking].id), false)
    end
  end
end
~~~~~~~

Showing your appreciation
=========================

If you use this system and want to sow your appreciation or have criticism, feel free to contact me in game as Keneanung per
message or tell.

If you want to do more than giving me a fuzzy warm feeling inside (which sadly doesn't buy me anything...) you can donate one
of the following (in order of preferences).

Time
----

Huh? Time? I can't transfer my time!

True, but you can use the time to create stuff. You can create code and contribute to the Basher (or any other of my
projects), send in ideas, write tutorials, help me with support stuff, create creative assets (I have some other projects
that heavily need a creative hand...) or do probably a great number of other things I currently can't think of. But contact
me and I'm sure we can work something out.

Money
-----

*This is valid as long as I am the sole maintainer of the project. As soon as other chime in, I will remove the two items
below for fairness reasons.*

You can send bitcoins to this address: 1M6DVCYeGmWN7yR3no3XjeZq3jrydKhYe7

I also have an Amazon wishlist: https://www.amazon.de/gp/registry/wishlist/20AAS3W9RZLAF?language=en_GB

Credits or other in game stuff
------------------------------

Just send anything my way if you think it could come in handy for me. But remember I'm not a Humgii!

Acknowledgements
================

Tool creators
-------------

- GitHub user @bradrhodes for his [GithubDocSync project](http://bradrhodes.github.io/GithubDocSync/)
- Webtoolkit for their [Base64 Javascript implementation](http://www.webtoolkit.info/javascript-base64.html) (used in
  GithubDocSync)
- Github user @chjj for the [marked Project](https://github.com/chjj/marked) (used in GithubDocSync)
