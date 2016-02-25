---
layout: post
title: Dual booting Windows 7 and (Arch) Linux, and the hassels involved
date: '2009-09-18 06:18:33'
---

This week I have been setting up my new computer - a complete beast with Intel Quad Core i7 processor, 12 GB memory, 4 * 1TB drives in RAID 1+0, etc. On this computer, I decided to put both Windows 7, which is provided for free through the [MSDN Academic Alliance](http://www.msdnaa.net/) and [Arch Linux](http://www.archlinux.org/) ( which I fell in love with the first time I tried it ).

Since getting an account with MSDN took a while, I decided to put Arch on the box first, even though the Windows bootloader is known to foul up GRUB and make it impossible to boot into linux.

First step was installing Arch.. Usually, this is quite hassle free, but because of the slow internet at the accomodation center at Bond University, I downloaded the Net Install CD so that I could install and download only what I needed. Sounds logical, right? Well, not when I tell you that, as I discovered, you have to login to access the wired network. When opening a browser, you're presented with a login screen though HTTPS, that has to be completed every time your IP changes. Problem is, the netinstall CD has no browser installed as it is command-line only, and as such, I had no way of authenticating with the network, which again lead me to being unable to download any packages for my system. So, what do you do?

### Logging into an HTTPS proxy through command line tools

My first though was to use links or lynx ( text-based unix browsers ), however neither were available on the netinstall CD, and I couldn't compile either from source since the build tools and dependencies were not there. At this point, I was certain I would have to download the full Arch install CD, and start all over again, however, I was not prepared to give up that easily. There is a reason I use Arch - to understand how things work from the ground up, and to force myself into exploring Linux.

At first, the only solution I could think of was to telnet into the login server over HTTPS, send the proper POST headers by hand, and thereby become authenticated. Finding the correct headers on my laptop was not a problem, however hand-typing them onto the linux shell posed a problem. Not in getting it right, but because the HTTPS connection of the login server had a timeout for requests at about 10 seconds... The end request looked something like this:

```
POST /login.pl HTTP/1.1
Host: login.bond.edu.au
Connection-type: keep-alive
Keep-alive: 300
Content-type: application/x-www-form-urlencoded
Content-length: 112

_FORM_SUBMIT=1&which_form=reg&source=<my IP>&destination=&error=&bs_name=<Student ID>&bs_password=<URL encoded password>
```

As you can probably imagine, hand-typing that in 10 seconds is not an easy task. Evidently it was not going to work, which was why I started exploring the unix philosophy of separation of tasks. Why should I type all that text, why couldn't the computer type it for me? I created a file with the request, and used the unix command "cat" to print the file. I then piped the output through my telnet connection as such:

```
cat request | telnet login.bond.edu.au 443
```

To my surprise, this just caused the connection to time out without any error message... After trying a multitude of alternative versions of the above, I concluded that parts of the request was probably printed to the server before the connection was actually established, which caused the server to disconnect the session.

I felt quite lost, and was very close to getting a full Arch install ( and thereby have to wait for about 5-6 hours for the download to complete... ), when I remembered the "wget" command. This is a command that allows you to download files from the web through HTTP/HTTPS/SCP/SFTP/FTP. Maybe it could also send a POST request?

Not only was wget included in the netinstall CD, but after looking at the manpages, I also found the argument "--post-file", which allows you to send urlencoded data through POST when submitting the request. I was saved! I stripped everything except the data from my request file, and issued the following command:

```
wget --post-file request --save-cookies s.cookie https://login.bond.edu.au/login.pl
```

Looking at the downloaded HTML file, I soon found that I had successfully been logged in, and I could start the actual installation!

Both the installation, and the subsequent configuration ( installation of GNOME, setting up drivers, etc.. ) posed no problem as usual, though it all took quite a while having to download it all though the 1 Mbit/s throttled connection at the student residences. Next morning however, my computer was up and running just the way I wanted it. Windows 7 next...

### Windows 7

First of all, I had to download Windows 7 from MSDN, which proved to be impossible from linux. It provided a downloader, which, when run through wine, simply refused to download the file properly.. In the end, I had to download the ISO on my laptop ( running Vista ), and burn the DVD from there. From here, the ride was smooth. Installation of Windows 7 was both painless and fast, and I was up and running in 30 minutes. Great!

Next was getting GRUB back on the MBR, since Windows overrides all other bootloades when installed. At first, I tried looking for a windows installer that could restore GRUB to the MBR, but this does not seem to be available, so I had to get down and dirty with the unix command line again. Hooray! =D

I rebooted, and started up from the Arch installation CD. From there, you have two options to restore the grub. Both involve getting your original Linux partition mounted, and then running grub-install from there.

 1. Boot the Arch Linux Live CD, mount your linux partition using `mount /dev/sd** /media/fl` where `**` is the device and partition of your Linux boot partition. Next, you have to run: `grub-install --root-directory=/media/fl /dev/sd*` where `*` is the device you wish to boot from..
 2. Open the "More Options" selection on the boot screen of the CD, and then highlight the option "[EDIT ME] Boot Linux Directly". Next, press 'e' to edit the line. Here, edit the line `root (hd0,0)` to match your device and partition. Next, edit the two other lines, and change /vmlinuz and /kernel ( can't remember the exact filenames ) to read `/boot/vmlinuz` and `/boot/kernel` respectively. Note that these are the default paths, but yours might differ. Also, you might have to change the line that contains `root=/dev/sda3` to fit your setup. Finally, press 'b' to boot the linux partition. You will now find yourself in your normal Linux install. From there, you can run `grub-install /dev/sd**` as in 1.

Why the two options? For some reason I didn't think of the first option until after I did #2. Maybe it will come in useful at some time...?

Now, to get Windows available from GRUB, edit `/boot/grub/menu.lst`, and uncomment the Windows lines at the bottom, and input the correct device and partition.

And then, you're done! Congratulations! You're dual-booting Windows 7 and Linux