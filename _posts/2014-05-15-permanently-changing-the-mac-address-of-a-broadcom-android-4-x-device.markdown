---
layout: post
title: Permanently changing the MAC address of a Broadcom Android 4.x device
date: '2014-05-15 20:35:32'
---

Wi-Fi devices all have a (mostly) unique address burned into them when they are manufactured so that a meaningful media access control (MAC) protocol can be developed. This MAC address needs to be unique on your network so that your Wi-Fi access point knows which device is sending it data, and which device it should reply to.

In most deployments, it should not be necessary to ever change your MAC, but there are some use-cases in which this ability can come in handy. First of all, you might want to change your MAC for privacy reasons (so people can't track your machine). Second, some networks apply (very ineffective) access control based on a list of "permitted" MAC addresses. Finally, some ISPs restrict Internet access to only specific MACs, and being able to change it gives you the freedom to use any device as your modem.

You may have noticed that I said the MAC is burned into the hardware, which begs the question: how are you able to change it? Well, your operating system reads the MAC from the card when it boots, but the OS can choose to put a different MAC into the data packets it sends out. This is often referred to as MAC spoofing. Exactly how you get it to do that though depends on the exact operating system you are running. Today, I will focus on Android.

If you head over to XDA or Google and do a quick search for "Change Android MAC", you will get a long list of forum threads and apps dealing with this issue. Most of them go something like this:

 1. Root your device (Google it)
 2. Install busybox (Google it)
 3. Run `adb shell`
 4. Run `su` to get a root shell
 5. Disconnect from any wireless networks
 6. `ifconfig wlan0 down`
 7. `ifconfig wlan0 hw ether 00:11:22:33:44:55`
 8. `ifconfig wlan0 up`
 9. Connect to your network again and your new MAC will be used

Perfect! Done.

Well, not quite.. Firstly, this solution will only work on some devices. Some devices will seem to succeed, but will keep using the old MAC when you start using the network, and others will successfully change the MAC, but then fail to connect to any networks. Furthermore, this change is **temporary**. If you turn on Airplane Mode, reboot your device, or in some cases even turn WiFi off and then on again, the MAC will return to its default value again.

Today, I am hoping to show you a more permanent approach that I believe should work on any device using a Broadcom chipset, but that also takes some more effort to pull off. ***SOME OF THE STEPS BELOW INVOLVE FLASHING YOUR DEVICE, WHICH MIGHT VOID YOUR WARRANTY AND BRICK YOUR DEVICE! I TAKE NO RESPONSIBILITY IF YOU GO AHEAD WITH THIS. YOU HAVE BEEN WARNED***. Also, before going ahead with anything below, make a note of your current MAC address so that you can restore it if something goes wrong. It is shown under Settings -&gt; About phone -&gt; Status -&gt; Wi-Fi MAC address.

First, install [Cyanogenmod](http://www.cyanogenmod.org/) on your device (or some other non-vendor Android, stock works fine too). Next, make sure your device is [rooted](http://www.androidcentral.com/root) and that you have [adb](https://developer.mozilla.org/en-US/Firefox_OS/Debugging/Installing_ADB) installed and working. Now, run `adb shell` followed by `su` to drop you into a root shell. Before we begin exploring the long way of doing this, we're going to see if you can take a little [shortcut](http://android.stackexchange.com/a/60805). If you have a file called `/persist/wifi/.macaddr`, just type `echo -n "001122334455" > /persist/wifi/.macaddr`, and **you are done**! This only exists on some devices (I suspect only on Nexus), but if it does, it saves you a lot of work.

If you're still reading, I assume that the above shortcut did not work for you, and so we need to take a few more steps. You see, it turns out that there is [an option](http://forum.xda-developers.com/showthread.php?t=1878506) in one of the very commonly used Android drivers that must be explicitly set in order for the MAC address to be changeable. There is a file, `/efs/wifi/.mac.info`, that contains your device's MAC address, but without this particular driver option, changing the content of that file will *not* change the active MAC.

The default CM11 kernels do not appear to have this turned on (at least the Samsung Galaxy S2/i9100 one doesn't), and so you will have to find one that does. In particular, you want to see if `drivers/net/wireless/bcmdhd/dhd_sec_feature.h` has the line `#define READ_MACADDR` in it (a patch might look like [this](https://github.com/dorimanx/Dorimanx-SG2-I9100-Kernel/commit/f88f0217a4e5d53d421338ae8bad2eff55adfa01)). If you happen to have a Galaxy S2/i9100, you can use the [DorimanX kernel](http://forum.xda-developers.com/galaxy-s2/development-derivatives/kernel-dorimanx-test-builds-t2415759) which already has it enabled. Flashing this new kernel should be as simple as using `adb push` to send the kernel's .zip file to the device, rebooting into recovery with `abd reboot recovery` and then installing the kernel .zip from there.

After flashing your shiny new kernel, your phone should boot normally and look just the same. The difference is that the kernel will now **read** `/efs/wifi/.mac.info` when the driver starts, and it will use that MAC address! This file is on the `/efs` partition, meaning that any changes will survive a reboot, so by executing `echo -n "00:11:22:33:44:55" > /efs/wifi/.mac.info`, we have now **permanently** changed the MAC of your device! Try rebooting and then going into Settings -&gt; About phone -&gt; Status again; lo' and behold, your MAC has changed.

Hope this has been helpful, and please leave feedback if you find a working kernel for another device, if you get an error of some kind, or if you have ideas about how any of the steps can be made clearer.