---
layout: post
title: Hot-swapping drives in Windows 7
date: '2009-11-09 02:43:06'
---

I have recently bought two external SATA docking stations - one internal ( i.e. it fits in a 5.25" bay, and loads the drive from the outside like a large floppy ), and the other one completely external and connected through eSATA. For the first couple of weeks, I thought hot-swapping was not possible with these, and kept rebooting if I wanted to swap out a drive, however one day I came across a setting in BIOS describing how SATA drives should be treated. It was set to "IDE compatible".. The other options were "Enhanced" and "AHCI". I tried googling this, and soon found that AHCI is actually a technology that enables plenty of the cool features of the SATA technology - most notably hot-swapping!

I enabled AHCI, booted up the computer, and Windows 7 presented me with a BSOD... Again, Google was my friend, and I found several other people who got the same problem when enabling AHCI after install. It seems as though Windows 7 checks for AHCI when installed, and determines then whether to load the AHCI drivers or not.. It then never checks again.... Smart...

Luckily, there is a solution.. First you have to get back into Windows my resetting the SATA drives to "IDE compatible" mode. Next, open up the registry explorer, and follow this guide: http://support.microsoft.com/kb/922976. If it is already set to 0, set it to 1, then to 0 again, and reboot. Now, set the drives to AHCI in BIOS, and reboot again. Hopefully your Windows should start up without a bluescreen.

Now, all your SATA drives will appear  when you use the "Safely remove device" icon near the clock in the bottom right corner. If you choose to remove a drive, you can eject it from there and then take it out and put in a new one. This is where the problems start to arrive though. Sometimes, this approach works without a problem, but sometimes Windows simply goes silent, and acts as though nothing has been connected at all. Other times, it tells you that it has found partitions, but that they are in RAW format, and have to be reformatted!

After living with this for a couple of days, I decided that there had to be a more stable way of doing this, and that was when I came across [HotSwap!](http://mt-naka.com/hotswap/index_enu.htm). This piece of software is made for managing hot-swap drives in Windows, and once installed, allows you not only to scan for new drives ( and load them properly! ), but also to safely remove them AFTER doing a spin-down.

After running this stand-alone .exe, you can set it to autostart with Windows. After that, whenever you want to swap a drive, just right-click the hotswap icon at the bottom right near your clock, safely remove the device you want to swap, exchange the drives and choose "Scan for changes" in the HotSwap! menu and up comes your drive!

Happy hot-swapping!