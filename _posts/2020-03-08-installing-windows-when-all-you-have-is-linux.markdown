---
layout: post
title: "Installing Windows when all you have is Linux"
date: '2020-03-08 13:22:58'
---

Okay, so, you are trying to install Windows on a laptop or something for
your friend. But you use Linux, and don't have a Windows box easily
accessible. You're armed with a USB drive, a Linux system, a Windows
ISO, and little more. Now what?

I'll keep this one brief, because if you're trying to do this, you
probably just want to get the damn thing working. And, like me, you are
quite possibly already annoyed at why the simple solutions don't work.

Depending on what you've tried so far, you may be in any one of these
stages:

 - You `dd`ed the ISO onto the USB drive, and it won't boot.
 - You created a single GPT FAT32 partition on the drive, tried to copy
   the files from the ISO over, and found that `install.wim` was too
   large to fit on a FAT32 system.
 - You created a single GPT NTFS (or maybe exFAT) partition on the
   drive, copied over the files from the ISO, and found that the
   computer wouldn't boot it.
 - You tried to [split the WIM] and use FAT32, only to find that when
   the installer starts (which it does), it then fails with ["A media
   driver your computer needs is missing"]. You found this surprising
   since [Microsoft recommend you do this].
 - You found [this post][trick1] (or maybe [this one][trick1-variant])
   and tried to create both a FAT32 *and* an NTFS partition. And
   everything seemed really promising until you get the error "Windows
   could not prepare the computer to boot into the next phase of
   installation", and you sag into your chair going "why is this so damn
   hard?!".

All right, so here's what you have to do:

 1. Format your USB drive as a GPT disk with two partitions, one FAT32
    with GPT code `ef00`, the other NTFS with GPT code `0700`. Roughly:
    ```console
    $ gdisk /dev/myusbdrive
    o
    n
    <enter>
    <enter>
    +1G
    ef00
    n
    <enter>
    <enter>
    <enter>
    0700
    w
    $ sudo mkfs.fat -F32 /dev/myusbdrive1
    $ sudo mkfs.ntfs -f /dev/myusbdrive2
    ```
 2. Mount the Windows ISO and the partitions:
    ```console
    $ sudo mkdir /tmp/iso
    $ sudo mount -o loop windows10-enterprise-1909-x64.iso /tmp/iso
    $ sudo mkdir /mnt/{win,boot}
    $ sudo mount /dev/myusbdrive1 /mnt/boot
    $ sudo mount /dev/myusbdrive2 /mnt/win
    ```
 3. Copy over all the files to the NTFS partition. Copy over everything
    **except** `sources` to the FAT32 partition. Finally, copy over
    `sources/boot.wim` to the FAT32 partition. You'll get some warnings
    about copying permissions, but you can ignore those.
    ```console
    $ sudo rsync -av /tmp/iso/ /mnt/win/
    $ sudo rsync -av --exclude sources /tmp/iso/ /mnt/boot/
    $ sudo mkdir /mnt/boot/sources
    $ sudo cp -a /tmp/iso/sources/boot.wim /mnt/boot/sources/
    ```
    This is [this trick][trick1], where we work around the FAT32 size
    limitations by using the FAT32 partition as a "launch pad" into the
    NTFS partition (which _can_ have large files).
 4. Unmount the USB drive
    ```console
    $ sudo sync
    $ sudo umount /mnt/boot
    $ sudo umount /mnt/win
    ```
 5. Plug it into the machine you want to install Windows on. You
    probably want to reset the BIOS while you're at it and enable secure
    boot (in "setup" mode). At the very least, make sure you boot in
    UEFI mode (not "legacy"). Boot from the USB drive — it should start
    the installer.
 6. Now we're going to _move_ the installer onto the drive we're
    installing onto! This is a [sneaky trick][trick2] to work around the
    Windows installer seemingly getting [very confused] on UEFI systems
    when there is more than one drive (like here, where our USB drive is
    inserted). We're basically going to replicate the install disk onto
    the internal disk, and then run the installer from the internal disk
    without the USB drive inserted. We want to do so in such a way that
    the final install isn't left with a bunch of empty space at the
    beginning of the disk (which is hard to reclaim), so we're going to
    place the NTFS partition at the end. We also want to _combine_ it
    with the split partition trick in case the machine cannot boot NTFS
    partitions.

    Here we go: press Shift + F10 to open a command prompt, then:
    ```batch
    > diskpart
    list disk
    select disk 0 REM this should be your internal disk
    list part
    REM this _clears_ the install disk, make sure you want to do this!
    clean
    REM now, we re-create the two-partition trick on the internal drive:
    REM X below is in MB; use the size of the disk - 10GB
    create part primary size=X
    create part primary
    select part 2
    format fs=ntfs quick
    # in case your disk is large, FAT32 partitions have a size limit:
    select part 1 REM this should be the big partition
    delete part
    create part primary size=10000
    select part 1 REM check that this is still the big partition
    format fs=fat32
    REM now, we need to format them
    list volume
    REM note down the drive letter for the USB drive.
    REM we'll assume it's C: below
    select volume 1 REM the volume for the FAT32 partition
    assign letter=f
    select volume 2 REM the volume for the NTFS partition
    assign letter=n
    REM all done
    exit
    ```
    Now we need to set up the files like before
    ```batch
    > xcopy /H /E C:\ N:\
    > copy C:\autorun.inf F:\
    > copy C:\bootmgr F:\
    > copy C:\bootmgr.efi F:\
    > copy C:\setup.exe F:\
    > xcopy /H /E C:\boot F:\boot REM answer D
    > xcopy /H /E C:\efi F:\efi REM answer D
    > xcopy /H /E C:\support F:\support REM answer D
    > F:
    > mkdir sources
    > copy C:\sources\boot.wim F:\sources\
    > exit
    ```
    Phew, okay, now, click the little X in the installer to exit. When
    the computer reboots, unplug the USB drive.
 7. We're almost done. When the installer starts, proceed normally
    until you get to the place where you're given the option of a
    "Custom" install. Choose it. When you're given the partition
    manager, select the partition at the start of the disk, and delete
    it. Then, select the "unallocated space" as the installation target.
 8. Finish installation (it should hopefully succeed!).
 9. To reclaim the final bit of space, open up an Administrator command
    prompt (Windows key → `cmd` → Ctrl + Shift + Enter), and run:
    ```batch
    > diskpart
    select disk 0 REM make sure this is the disk with the NTFS partition
    list part
    select part N REM N should be the 10G NTFS partition
    delete part
    list volume
    select volume M REM M should be the volume immediately before N
    extend
    exit
    ```
 10. Enjoy?

If this worked for you, or if you had to do something differently,
please let me know on [Twitter](https://twitter.com/jonhoo) or by
e-mail so I can update this accordingly :)

 [split the WIM]: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/split-a-windows-image--wim--file-to-span-across-multiple-dvds
 ["A media driver your computer needs is missing"]: https://support.microsoft.com/en-us/help/2755139/a-media-driver-your-computer-needs-is-missing-or-a-required-cd-dvd-dri
 [Microsoft recommend you do this]: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/install-windows-from-a-usb-flash-drive#troubleshooting-file-copy-fails
 [trick1]: https://win10.guru/usb-install-media-with-larger-than-4gb-wim-file/
 [trick1-variant]: https://techbit.ca/2019/02/creating-a-bootable-windows-10-uefi-usb-drive-using-linux/
 [trick2]: https://neosmart.net/wiki/setup-was-unable-to-create-a-new-system-partition/#Fix_2_Manually_create_the_boot_partition
 [very confused]: https://answers.microsoft.com/en-us/windows/forum/all/windows-10-fresh-install-fails/f9614ae4-6dbd-4715-9a81-8586b16dfaf7?page=2
