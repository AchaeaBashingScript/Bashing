A bashing script Achaea
=======================

What's this?
------------

While bashing (or hunting NPCs) in Achaea is not overly complicated, it is sometimes useful to handle targets in a certain
order instead of going through the seemingly random list from top to bottom. Different types of targets in an area make
basing even more cumbersome. To avoid having to target specific NPCs by number (which is error prone and slow), this project
was born.

Requirements
------------

- Mudlet
- gmcp enabled
- **svo**

Downloads and Releases
----------------------

The bashing script can be downloaded on the [github release page of the project](https://github.com/keneanung/Bashing/releases).

Stable releases are versioned with the versioning scheme `vXX.XX` where each XX stands for a number. The latest official
stable release has a green tag on the left side.

Releases with an orange tag are pre-releases for testing. *Those are automatically generated and not guaranteed to work.*
Additional to a numeric version number, the versioning scheme contains a short commit hash and a branch name. If you notice a
problem with a pre-release, please include this information in your bug report.

Quickstart
----------

1. Download the Bashing.mpackage
2. Import the package into Mudlet
3. Deactivate or delete the keybinding of F2 that comes with svo.
4. Use the alias `kconfig bashing toggle` to enable the script
5. Start killing things. Acceptable targets must be killed at least once in an area to register them with the bashing script.
   The basher will use the "target" variable or the in game target as a fallback, if there is no item in the prio list.
6. Keep bashing away using the F2 keybinding to work yourself down the list.

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

Shield handling
---------------

For classes with a quick and easy way to handle shielding NPCs, the basher has a very simple way to use it.

First turn the autoraze option on, using the alias `kconfig bashing raze`. This will enable switching the command used when
the denizen you attack shields. Additionally you need to configure the command used for autorazing. That can be done with
`kconfig bashing razecommand <command>`.

Congratulations, you will now raze the shield of NPCs whenever needed.

Fleeing
-------

The basher supports 2 ways to flee from dire situations, be it a stronger NPC entering your room, a tell you need to
concentrate to answer or luring NPCs into another room. The basher will always try to recognize the direction you entered a
room from and flee into that direction. *If that exit is not available, it will the direction it recorded before.* It will
issue a warning in that case. You can use the alias `flee <command>` to set that manually.

The first way is the manual way. Simple press the keybinding `F3` to stop attacking and move ASAP.

The second way is automated and may be activiated, if the **average** damage you have taken in this room between 2 attacks is
higher than you have at the next attack with an configurable threshold. The basher will also issue a warning, if average the
damage between 2 attacks is higher than your current health and another theshold. You can enable and disable that with the
alias `kconfig bashing autoflee` and the configure thresholds with `kconfig bashing fleeat <health amount>` and 
`kconfig bashing warnat <health amount>`.

Configuration
-------------

The current configuration can be shown with the alias `kconfig bashing`. All items in red are clickable and will either
toggle the item or set the alias to the command line, so you only need the add the value you want to set.

Acknowledgements
================

Tool creators
-------------

- GitHub user @bradrhodes for his [GithubDocSync project](http://bradrhodes.github.io/GithubDocSync/)
- Webtoolkit for their [Base64 Javascript implementation](http://www.webtoolkit.info/javascript-base64.html) (used in
  GithubDocSync)
- Github user @chjj for the [marked Project](https://github.com/chjj/marked) (used in GithubDocSync)
