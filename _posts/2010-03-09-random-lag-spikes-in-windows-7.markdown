---
layout: post
title: Random lag spikes in Windows 7
date: '2010-03-09 23:26:48'
---

**Update**: It turns out the issue is even more general than I thought at first. It is in fact not just the HTC mobile sync program that causes these freezes; it is in fact any mobile syncing application. After launching the Sony Ericsson PC Suite today, I noticed that the issue returned immediately. I killed the process, and it ended again. Seems as though Windows 7 has issues dealing with mobile syncing software if the device is not connected..?

For the past couple of weeks, my graphics card had been acting up. Or so it seemed. Every 5-6 seconds, the screen would freeze for a brief moment - just long enough to notice. It was only the screen though, because music playing in the background would keep going, and any other application would proceed as though nothing had happened. This lead me to believe that my nVidia 8600 GT was to blame.

After looking around the web, I found that several people were complaining about random lag spikes with the newest nVidia drivers, and thus my suspicion was reinforced. I tried uninstalling the drivers, and installing 6 different, previous versions of the driver pack, but to no avail.

A couple of days ago I'd had enough - it is really annoying when the mouse stops moving every five seconds - and so I decided to order a brand new graphics card. After all, if the graphics card is acting up, what is more likely to fix the issue than a new graphics card?

Well, it arrived in the mail yesterday, and to my great surprise, the issue persisted. And this was an ATI card - no nVidia drivers were even installed on the system. The mystery remained.

In order to find the cause of these lags, I fired up the Task Manager and kept an eye on the CPU usage graph. It turned out that one of my CPU cores spiked at about 10% every time the screen froze. I switched to the process view, but there were no processes suddenly jumping to the top on every freeze... Odd.. There was a process called `fsynsrvstarter` - with the suspicious description "TODO: &lt;description&gt;" quite close to the top. It didn't use any CPU, it just sat there.. And so I figured I'd Google it just in case.

At this point, I came across [this forum post](http://android.modaco.com/content/htc-hero-hero-modaco-com/293112/htc-sync-2-0-4-problem-on-xp-sp3/) explaining that this process was spawned **every 4 seconds** by HTC Sync. This seemed as though it aligned too perfectly with my spikes, so I decided to uninstall HTC Sync and see what happened. And what do you know? The spikes were gone..

So, I now own two graphics cards (albeit one somewhat outdated) which both work well, but are brought to their knees by such a complex piece of software as a mobile phone syncing program (an inactive one at that).

I hope this post will solve your problem before you decide to buy a new card like I did.