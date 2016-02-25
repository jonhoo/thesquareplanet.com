---
layout: post
title: Running Dungeon Keeper on Linux
date: '2014-02-02 15:22:07'
---

After reading this great [post](http://www.baekdal.com/opinion/how-inapp-purchases-has-destroyed-the-industry/) on how in-app purchases are ruining the gaming industry, I felt an urge to play Dungeon Keeper again. Since I run Linux, however, playing games is not always such a trivial affair. WineHQ (unhelpfully) told me that Dungeon Keeper does [not run very well](http://appdb.winehq.org/objectManager.php?sClass=application&amp;iId=1978) under wine 1.5, but given that 1.5 was released early last year, I figued I'd give it another shot.

I headed over to Good Old Games who provide DRM-free versions of old games, and bought [Dungeon Keeper Gold](http://www.gog.com/game/dungeon_keeper) edition for just below $6. After downloading the installer, I ran it through wine, and lo' and behold, the installer ran without problems. At the last screen, I pressed "Launch game", and to my surprise the game also started without a hitch. No stuttering in video or audio. I started the single player campaign, and nothing seemed to be wrong at all. So much for old WineHQ entries.

Then I quit the game to see whether it would still work when I started it "normally". I quickly discovered that there was no "normal" way to start the game. The game is run through DOSBox, and GOG have provided Windows shortcut files (.lnk) for launching the game with the appropriate options. Unfortunately, wine doesn't let you launch .lnk files, and just running DOSBox gave me nothing more than a shell (which, to be fair, was to be expected). Time to start digging.

It turns out that .lnk are part binary, part text, and by catting the file, you do see what commands it would run when executed on Windows. I'll save you the details, but you essentially need to pass DOSBox two configuration files provided by GOG: dosboxDK.conf and dosboxDK_single.conf. You also need to run this command from **inside the `DOSBOX/` directory!** Being in the game's root directory will not work, and the game won't start.

Realizing that DOSBox is also supported natively on Linux, I started to wonder whether I could avoid wine alltogether.. Seems silly to start wine to start DOSBox to start the game if I don't have to. So, I replaced `wine DOSBox.exe` with just `dosbox`, and everything worked just as well! In fact, it turns out that DOSBox has already been [tested with Dungeon Keeper](http://www.dosbox.com/comp_list.php?showID=758&amp;letter=D), so this shouldn't have come as a surprise I suppose.

Finally, to clean up, I [extracted](https://gist.github.com/jonhoo/8769596#file-setup_icons-sh) the Dungeon Keeper icon files and created a [Desktop Entry file](https://gist.github.com/jonhoo/8769596#file-dungeon-keeper-deskto) so that I can now start the game directly from my launcher:

![Dungeon Keeper launcher](/blog/content/images/2015/05/2014-02-02-151834_1600x900_scrot.png)

Hope this has been useful, now go and be evil!