---
layout: post
title: Decrypt home partition on login
date: '2012-10-23 20:41:44'
---

After switching to systemd a while back, I have been annoyed by having to enter the decryption key for my /home partition on every boot. My root partition is unencrypted, as are all the other partition except /home, but having to enter the key makes the boot process seem slower than it really is since the password prompt appears in a plain white-on-black tty. Also, due to the concurrent nature of a systemd boot, the password prompt is often intermangled with other boot messages. This happens even with the "quiet" boot parameter since fsck results are still printed. For a while I tried to ignore the problem, but one lazy afternoon I decided to come up with a somewhat prettier solution.

Before I get into the exact details, let me start off with my base configuration and what I wanted to achieve:

# Configuration

 - Arch Linux (64-bit)
 - Unencrypted /root, /boot, /var, etc.
 - Encrypted /home partition using LUKS through dm-crypt + cryptsetup
 - SLiM login manager
 - PekWM + kupfer launcher + tint2 panel

Note that none of these are requirements for the solution I am going to give below apart from the encrypted home partition. Also, it is worth pointing out that my solution is in no way specific to my login manager, my DE (or lack thereof) or anything else except GTK and dm-crypt (and by extension cryptsetup).

# Target boot process

 1. System boots
 2. systemd starts all daemons and filesystems EXCEPT /home normally
 3. systemd boot process completes without user intervention
 4. Login manager or login prompt is displayed (*yes, this solution can work without a login manager*)
 5. An X session is started for a user
 6. Upon login, a password prompt is displayed
 7. Upon typing the correct password, the encrypted home partition is decrypted and mounted
 8. Any user .xinitrc is executed, starting whatever WM/DE and other applications the user wants

# Solution

OK, so now that we have gotten the prerequisites and our goals out of the way, let us see how we can accomplish this.

Before digging into the nitty-gritty details, here is a high-level sketch of the solution for the impatient:

 - Set the home partition to noauto in both /etc/fstab and /etc/crypttab to avoid automatic decrypting/mounting
 - Write a program that can prompt for a password, decrypt a partition and mount it
 - Place a bootstrap .xinitrc in the users' home directories when the home partition is not mounted
 - In this bootstrap .xinitrc, which will be executed if the home partition has not yet been mounted, run the program from point #1
 - After running the program, wait for the mount to finish and execute .xinitrc again
 - If the mount succeeded, we're starting the user's .xinitrc, otherwise, we're showing the password prompt again

## Challenges

 - How do we give the program permissions to decrypt and mount?
 - Given that GTK programs [cannot be run as root](http://gtk.org/setuid.html), how do we still display a password prompt?
 - How do we preserve the user's X session when the new /home is mounted, considering the credentials for connecting to it are stored in ~/.Xauthority when X is started?

## The nitty-gritty

Although there may be many ways of solving the above, I have decided to solve it by writing two simple applications in C, crypsetup-gui and cryptsetup-gui-gtk. The latter displays a password prompt and, upon the user pressing Enter, prints this password to stdout. The former takes the name of an encrypted partition, looks through /etc/crypttab to find the real disk partition, displays the password prompt by spawning cryptsetup-gui-gtk, calls cryptsetup with the correct parameters to decrypt it, mounts the partition according to /etc/fstab and then returns a value depending on whether all the operation succeeded or not.

To overcome the first problem, I opted for using the [setuid bit](http://en.wikipedia.org/wiki/Setuid#setuid_on_executables) rather than using sudo both to avoid having a dependency on sudo, but also to prevent system administrators from having to grant sudo rights in order to execute the program. I believe the implementation of cryptsetup-gui should be safe enough to not open any security holes, but please read the README and the code to make sure yourself!

Solving the second problem now becomes very easy, since cryptsetup-gui can simply drop its permissions by setting the effective UID = real UID before opening the password prompt, allowing cryptsetup-gui-gtk to execute with no special permissions.

The third problem is not so much a problem as something one must consider. Fixing it is merely a matter of remembering to copy the .Xauthority file to some temporary location before mounting and then moving it back after mounting.

During the development of this small set of tools, some unanticipated problems did arise:

 - The aforementioned disallowance of running as root in GTK programs
 - The .Xauthority problem
 - The working directory in .xinitrc (thus the working directory of the new user's session) remaining the unmounted /home/ (see [this forum thread](https://bbs.archlinux.org/viewtopic.php?pid=1178788))
 - The fact that cryptsetup and mount do not work correctly if EUID != RUID != 0, meaning that it is not sufficient to set the EUID of a running process to root in a setuid program

Luckily, all of these have been overcome, and they are usually mentioned in the source code.

# Getting it!

If you're so lucky you're also running Arch Linux, I've posted all the needed files in the package [cryptsetup-gui](https://aur.archlinux.org/packages.php?ID=63776) in the AUR. This will install everything in the correct places, with the correct permissions, except for the bootstrap .xinitrc which you will need to put in place yourself (instructions are provided on install).

On other distributions, install should not really be all that difficult either. Download the source code from [GitHub](https://github.com/Jonhoo/cryptsetup-gui), run `make install`, or optionally `make DESTDIR=/some/directory install` if you want to sandbox it, and make will put all the files in the correct places and set the right permissions. Note that this will not let you easily remove the application again. For that, feel free to create a package if you know how, or otherwise ask someone to do it for you. It should be fairly straightforward. The program also only depends (AFAIK) on glib2 and cryptsetup, but if you find any others, let me know!

The only action required after installing cryptsetup-gui or running make install is to put a copy of the .xinitrc bootstrap file (which make install puts in `/etc/skel/.xinitrc-cryptsetup-gui`) in the unmounted home directory of the users you want to be able to mount /home on boot. This process is fairly straightforward:

 1. Login as root (since /root is not under /home)
 2. `umount /home`
 3. `cp /etc/skel/.xinitrc-cryptsetup-gui /home//.xinitrc`
 4. Repeat above step for every user with a home directory in /home
 5. `mount /home`
 6. Reboot and enjoy!

# Shortcomings

 - Needs setuid bit...
 - Does not respect any special options in /etc/crypttab (this could be fixed)
 - Provides no clear error messages to end users (merely re-displays the password prompt)

# Final remarks

So, that is my little contribution to the world. Hopefully someone will find it useful!

Again, the code is on [GitHub](https://github.com/Jonhoo/cryptsetup-gui). If you find any bugs or potential improvements, or if you just have comments on the design, please feel free to contact me either there using the "issues" tab, via email, or via comments to this post.
