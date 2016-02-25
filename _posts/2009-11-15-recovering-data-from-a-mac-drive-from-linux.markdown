---
layout: post
title: Recovering data from a Mac drive from Linux
date: '2009-11-15 09:29:35'
---

The Mac of a friend of mine crashed the other day - complete harddrive failure. He turned it into the Apple store, and they decided to give him a new disk because they said they couldn't recover the old one. Somehow, he managed to talk them into leaving him with the old drive so he could try to get at least some of his data back. My friend then came to me, and asked me to have a look at what I could find.

He had already tried to hook the drive into another mac, but it just froze every time he tried to enter a folder on the drive. The same happened when I used my SATA docking station, and attempted to either access or repair the drive through a piece of software called [MacDrive](http://www.mediafour.com/products/macdrive/). It seemed as though all hope was lost.

I decided to give it another shot from Linux, just to see if I could somehow avoid the corrupt files, and copy only those that could be properly read. Turns out, Linux didn't even break a sweat when seeing the corrupted harddrive. All I had to do ( using Arch Linux that is ) was this:

 1. Attach drive to my SATA dock
 2. Mount the drive: `mount /dev/sdg2 /mnt/ext`
    - This assumes the external drive is sdg, check `fdisk -l` to find attached drives
    - Mac-formatted drives have at least two partitions ( one is the boot partition ). Therefore, you must mount partition two ( or whichever is formatted as HFS+ )</li>
    - Because Apple decided to use journaling on their HFS+ drives, these are not writable from Linux. Either live with it, or insert the drive into a Mac, open up the terminal ( usually Applications/Utilities/Terminal ) and run `diskutil disableJournal /dev/disk#` where # is the drive number. Find the drive number by running `diskutil list`. For more info, see: http://castyour.net/node/40
 3. Run `cd /mnt/ext/`
 4. Navigate to whatever folder you want to copy and run `cp -R <folder> <destination>`
 5. The cp command will then dutifully copy all the files it can read properly into your destination folder, and tell you if it can't read a file. It will automatically skip them.
 6. Your files are saved!