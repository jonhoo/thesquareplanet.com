---
layout: post
title: Game Dev Tycoon on Linux
date: '2013-05-01 11:38:54'
---

Yesterday [Game Dev Tycoon](http://www.greenheartgames.com/app/game-dev-tycoon/) went viral with its decision to punish pirates in an [unusual](http://www.greenheartgames.com/2013/04/29/what-happens-when-pirates-play-a-game-development-simulator-and-then-go-bankrupt-because-of-piracy/), but quite ingenious way. Helping their popularity was probably the fact that the game is available for both Windows, Mac and Linux, and so users were downloading it like crazy! Unfortunately, the Linux version seems to be riddled with bugs at the moment, and for some users getting the game to run in the first place seems to be causing massive headaches.

I can't help much with the in-game bugs (that I know the developers are hard at work on), but getting it to run on Linux turns out to be easier than expected. The only in-game bug I have a fix for is the one that makes the game hang when trying to move out of the garage - see the bottom of this post for the workaround.

Game Dev Tycoon is built using [node-webkit](https://github.com/rogerwang/node-webkit), which essentially lets the developers build the game using web tech, while still being able to provide a binary to users. The way node-webkit packages applications is that the source code and resources are put in a zip file, and this zip file can then be passed as an argument to the nw binary, which will extract it and run the code using node and webkit (as the name implies). To make installation for end-users "easier", the node-webkit documentation suggests that a binary is generated like this:

```bash
cat /usr/bin/nw app.nw > app && chmod +x app
```

which allows a user to simply run `./app`. The problem with this is that this means the user is locked in to using the nw binary as compiled on the developer's computer, which turns out to be a 32-bit Ubuntu system. This isn't great for 64-bit users and users on bleeding-edge distributions like Arch Linux, who then have to install all sorts of legacy libraries (`lib32-gconf`) and ugly symlink hacks (`libudev.so.0 -> libudev.so.1`) to make it run.

So, how can we do better? Well, the node-webkit documentation does say

> In general, it's recommended to offer a .nw for download, and optionally "merged" versions for the platforms where this makes things simpler.

but the developers didn't do this. Is all lost? No. As it turns out, the unzip program is quite smart, and can extract zip files even if they're appended onto another file! This means we can simply run

```bash
tar xzvf game-dev-tycoon.tar.gz && unzip gamedevtycoon
```

And all the source files of the game will be made available to us in the current directory! Now, all we have to do is install/compile node-webkit ourselves (so no 32/64-bit problems and up-to-date libraries) and run

```bash
nw ./
```

and the game will run as advertised with no more hassle or hacks. Yay!

I notified the developers that the code could be extracted in this way, and the reply I got was

> Yes, we are aware of this.
> If people don't abuse this, there isn't an issue.

Finally some game developers who understand the name of the game!

For those of you running Arch Linux, I've written a PKGBUILD which does a cleaned-up version of this and made it available in the [AUR](https://aur.archlinux.org/packages/game-dev-tycoon/) and on [GitHub](https://github.com/Jonhoo/gamedevtycoon-PKGBUILD).

**Update**: many Linux users are reporting an issue with not being able to move out of the garage (the loading bar just runs forever). The fix has been posted by several people on the GDT forums, and it is simply due to Linux having case-sensitive filenames. The workaround is simply to run

```bash
mv images/superb/level2Desk.png images/superb/level2desk.png
```

after running unzip, and everything should be working smoothly.