---
layout: post
title: Setting up a virtual development server
date: '2009-12-14 09:37:05'
---

As a web developer, I often come up with interesting new concepts that I want to try out. Occasionally, these require more than simply HTML, CSS and JavaScript, at which point I need to begin uploading my PHP (my language of choice) files to a remote server running apache, test the page there, make adjustments in my local code, upload and test again. This is quite slow compared to the very efficient development cycle of plain old HTML where you can preview what you're doing instantly in the browser.

Whilst some IDEs have support for FTP uploading directly from the editor, this still means you have to wait for the upload to complete. Also, If you want to delete files or rename folders, it often requires you to start up a separate FTP client anyway. Wouldn't it be great if you could work with your PHP (or whatever server-side language you prefer) files directly on your computer, and access them directly through your browser without any intermediate steps? Just as if it was static HTML...

There are two ways you can do this; one is to install all the server-side software on your own computer and set it up so that it points to the directory you work from as its directory root. The other, which I will be telling you how to set up, is to run a virtual server on your box. The reason I prefer this approach is that it keeps a separation between your own computer and the server, and at the same time allows you to set up your server to match the server you will be deploying your application on.

So, first of all, grab a copy of Sun's [VirtualBox](http://www.virtualbox.org/). This piece of software allows you to set up virtual computers running whatever OS you want it to. Next, download the ISO containing your favorite server OS (I have chosen [Arch Linux](http://archlinux.org/), but this guide should apply to most Linux-based OSs, and the guiding principles should be applicable to any server OS). After installing VirtualBox, create a new Virtual Machine (VM). You can name it anything you want, and set how much RAM it should have, its hard-drive size and various other parameters. Usually the defaults are fine. When your OS has finished downloading, right-click your newly created VM in VirtualBox and select settings → Storage → Click the image with a CD icon → Click on the small folder icon with a green flick on it (The Virtual Media Manager) → Click add in the new window that pops up and select your ISO → Select the image that appears in the list and click "Select" → Click OK

Next, we need to do some low-level dirty stuff to make the host OS (Your computer) can connect to the guest OS (The server) through for instance port 80 (HTTP) and port 22 (SSH).

 1. Select "Network" in the settings dialog for your VM.
 2. In "Adapter 1", make sure the drop-down has "NAT" selected.
 3. Click advanced.
 4. Set the adapter type to PCnet-PCI II.
 5. Click OK and close VirtualBox completely.
 6. Open up the VirtualBox configuration file for your VM in notepad or similar (On my Windows 7 install, it is located in `C:\Users\<username>\.VirtualBox\Machines\<Name of VM>\<Name of VM>.xml`)
 7. At the top where it says: `<ExtraData>`, append the following code: ```xml
<ExtraDataItem name="VBoxInternal/Devices/pcnet/0/LUN#0/Config/apache/GuestPort" value="80"/>
<ExtraDataItem name="VBoxInternal/Devices/pcnet/0/LUN#0/Config/apache/HostPort" value="8888"/>
<ExtraDataItem name="VBoxInternal/Devices/pcnet/0/LUN#0/Config/apache/Protocol" value="TCP"/>
<ExtraDataItem name="VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/GuestPort" value="22"/>
<ExtraDataItem name="VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/HostPort" value="2222"/>
<ExtraDataItem name="VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/Protocol" value="TCP"/>```
 8. Save the file

What we just did was to tell VirtualBox that we want to forward the port "8888" on the host to port 80 on the guest, and similarly port 2222 to port 22. The reason we had to change the network adapter type to PCnet-PCI II in step 4 was that, as you can see from the strings you added to the XML, they reference `/pcnet/` which only works on the PCnet-type cards. If you use the intel-based ones, you need to find the shorthand for those (shouldn't be too much of a hassle).

Allright, so now we have the VM itself sorted out, next we need the server up an running. Time to start up your VM for the first time. This guide will not go through the actual OS install as it is way outside its scope, but generally, you don't need any GUI stuff, and should select any server software you'll need if you get the choice.

Next, you should install the VirtualBox guest OS additions. Under "Devices" in the VM window, select Install Guest Additions. This will download and mount an ISO image with the install files for most guest OSs. For a more in-depth explanation see [this link](http://www.dedoimedo.com/computers/virtualbox-guest-addons.html). From Linux, mount the CD and `cd` to the CD directory (pun actually not intended...), then run

```
sudo sh ./<script-relevant-for-your-architecture>
```

for example

```
sudo sh ./VBoxLinuxAdditions-x86.run
```

This should compile and install the relevant modules. You will also have to add two modules to your startup process: `vboxadd` and `vboxvfs`. The first is the base system for the VirtualBox Guest Additions, and the second one is the file system controller that allows you to access the shared folders set by the host. Some OSs also have these things available through repositories. In Arch for instance, the relevant packages are in the package `virtualbox-additions` in community. To install, just type `pacman -S virtualbox-additions`.

Under Arch, edit `/etc/rc.conf` and add the two said modules to the MODULES array (i.e. `MODULES = (vboxadd vboxvfs)`. Since your there, you might want to add `httpd` and `sshd` to your DAEMONS list as well. You should also add the following to your `/etc/hosts.allow`: `httpd: ALL` and `sshd: ALL`. This allows the host to connect on those ports.

So now that the guest has its additions, we need to install the server software. I won't go through the specifics here, but in my case, I installed Apache2 with PHP and PostgreSQL.

And so, to tie it all together: At this point, you have a working server, and after a reboot going to http://locahost:8888/ on your host should take you to the default start page in whatever web server you've set up. You should also be able to connect to SSH if you've set that up. Thus far though, you will still have to transfer your files to the server to test them there. This is where VirtualBox's shared folders come in.

In the VM window, select "Devices" → "Shared Folders". Here, add your development folder as a new shared folder with full access and click OK. If you run a GUI guest you should now be able to access the folder as a network drive. If not, however, you need to do some more console magic. To get the folder to mount automatically in Linux, all you have to do is add the following line to `/etc/fstab`

```
<Name of shared folder>    /srv/http/    vboxsf    defaults    0    0
```

The name of the shared folder is stated in the Shared Folders dialog we opened earlier.

Next, run `sudo mount -a` to mount the new folder. This should allow you to navigate to `/srv/http` on your guest OS and see all the files in your development folder. Finally, set up your web server to have `/srv/http/` as its document root, and you should be able to access any of your projects at http://localhost:8888/path/to/file/from/development/folder/ from your host the instant you save a file with all the bells and whistles of a fully-fledged web server.

If you experience Apache serving you old versions of a file even though you KNOW you've made a change, edit the Apache config (`/etc/httpd/conf/httpd.conf` on Arch), and uncomment the line saying `EnableSendFile off` and restart Apache.

Enjoy your new upload-free development environment!

References:

 - http://www.sitepoint.com/blogs/2009/10/27/build-your-own-dev-server-with-virtualbox/
 - http://rotwhiler.wordpress.com/2008/10/09/mount-virtualbox-shared-folders-automatically-using-fstab/
 - http://www.tanjir.net/2009/01/virtualbox-shared-directory/