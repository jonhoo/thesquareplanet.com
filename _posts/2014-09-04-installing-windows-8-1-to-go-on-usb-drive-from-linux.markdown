---
layout: post
title: Installing Windows 8.1 to USB drive from Linux
date: '2014-09-04 21:06:41'
---

Linux is great - we all know this. However, as most Linux enthusiasts painfully experience more often than they'd like, Windows is still occasionally needed for certain applications. While WINE and VirtualBox VMs takes care of most use-cases, there is still the occasional game or application that you'd really just rather run in a plain old Windows environment with no layers between the OS and the hardware. Having an external drive you can boot Windows directly from is perfect for this purpose, and as MIT offers [Windows 8.1 Enterprise for free](http://ist.mit.edu/windows/81/enterprise) to its students, I figured I'd take a stab at it.

So, with Windows 8, Microsoft introduced [Windows to Go](http://www.microsoft.com/en-us/windows/enterprise/products-and-technologies/devices/windowstogo.aspx) which (in theory) lets you install the operating system onto an external drive and plug it into any machine. The big change from Windows 7 was that WtG installs drivers beyond what is needed for the initial system, and thus you will (again, in theory) end up with way fewer crashes and errors than before. Unfortunately, WtG only works with a select few "[certified devices](http://technet.microsoft.com/en-us/library/hh831833.aspx#wtg_hardware)", and so despite being the proud owner of a brand new [MyDigitalSSD OTG USB 3.0 SSD drive](http://mydigitalssd.com/mobile-ssd.php) which should run Windows 8.1 without any problems whatsoever, I was stuck with an empty drive and no new games to play.

Luckily for me, Microsoft has released something called the Windows Assessment and Deployment Kit, which eases the job of administrators for big Windows deployments. The Windows ADK includes a tool called ImageX that lets users manipulate and deploy Windows installation images, and ingramator over at the [Neowin forums](http://www.neowin.net/forum/topic/1134268-tutorialwindows-8-to-go-without-enterprise-edition/#entry595496162) has found that this tool can be used to install Windows 8.1 directly to a disk without going through the setup program, thus bypassing the checks for "certified" hardware! This sounds perfect - if only you could run ImageX from Linux.

Okay, so not quite perfect - we need to run Windows in order to install Windows... Well, time to download a (free and legal!) [Windows VM image](https://www.modern.ie/en-us/virtualization-tools) and see if we can't get the job done from there. I'll wait while you set it up...

So you've got your shiny new Windows VM up and running, you've downloaded the 8.1 Enterprise ISO and [GImageX](https://www.autoitscript.com/site/autoit-tools/gimagex/) (GUI for ImageX), you've mounted the ISO in the VM so you can get to the install.wim file, and you're about to launch GImageX for the first time. Then you realize that, damn, you've forgotten that you can't see your USB from inside the VM. Oh well, just add it under USB devices and be on our way. "New device recognized" - yeah yeah, come on already. "Device failed to start". What? So, it turns out that although VirtualBox technically "supports" USB 3.0 devices, most of them won't actually work properly with a Windows guest OS (see the comments [here](https://www.virtualbox.org/ticket/8873)). So close, and yet so far... There has to be something clever we can do! This is Linux after all! Can't we just fake it?

I'm glad you asked. See, VirtualBox has this internal feature called "[raw host hard disk access](https://www.virtualbox.org/manual/ch09.html)" which lets you expose a drive or partition from the host OS directly to the guest OS. This way, the drive won't be seen as a USB device by the Windows guest, but rather as just another internal disk. Any writes or modifications made to the disk inside the guest VM will be written directly to the real disk. Perfect! Okay, so you plug in your USB 3.0 storage device, find its device path (let's say it's `/dev/sdb`), and then do:

```
VBoxManage internalcommands createrawvmdk -filename /path/to/file.vmdk -rawdisk /dev/sdb
```

Permission denied? Oh, of course:

```
sudo VBoxManage internalcommands createrawvmdk -filename /path/to/file.vmdk -rawdisk /dev/sdb
```

All we then have to do is mount `/path/to/file.vmdk` as a SATA drive in the VM, and -- "permission denied" again?

```
sudo chmod 777 /path/to/file.vmdk
```

That should do it, right? I guess not. It turns out you (perhaps obviously) need to change the permissions of `/dev/sdb` in order to let VirtualBox manage the device completely.

```
sudo chmod 777 /dev/sdb
```

Ah, yes, that did it. Back to Windows. First, we [create a new, empty partition](http://windows.microsoft.com/en-us/windows/create-format-hard-disk-partition#create-format-hard-disk-partition=windows-7) (remember to set it as active/bootable!) on our new disk. Next, we open GImageX, go to the "Apply" tab, select install.wim from the mounted 8.1 ISO as the source, select our new partition as the destination, make sure the checkboxes are **unchecked**, and then click Apply. This process takes a little while (it's installing the OS), so go get a cup of tea while you wait.

After this process is done, open an Administrator command prompt (Windows key -&gt; type `cmd` -&gt; Ctrl + Shift + Enter), go to your new WtG drive (type `X:` and press enter), navigate to System32 (`cd \Windows\System32`) and run

```
bcdboot.exe X:\Windows /s X: /f ALL
```

And that's it. You should now be able to turn off the VM, reboot your machine and boot directly into Windows 8.1 from your USB drive. The first time it will ask you some installation questions and such, but after that you're home free! Now go play some games or be productive in Lightroom or something, and then we can go back to hacking on Linux in a couple of hours.

Enjoy!