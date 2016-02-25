---
layout: post
title: WWAN on the X1 Carbon (3rd gen.) in Arch Linux
date: '2015-10-09 20:31:55'
---

A while back, I got my hands on the 3rd generation Lenovo X1 Carbon. Having been a happy owner of the first generation, and intentionally skipped the second generation, I was obviously excited. With my X1 Carbon, I also chose to add the WWAN LTE card (a Sierra Wireless EM7345) so that I can work while on the road using a data SIM.

Unfortunately, getting mobile connectivity on relatively modern hardware under Linux is not an entirely straightforward process. First, you need to find a provider that has a) a GSM network, b) allows data-only SIMs, and c) that allows the use of their SIM cards in laptops. Luckily, I recently switched to [Ting](https://ting.com/) (partially because of these requirements), which do provide you with such a setup. However, after getting my WWAN card's IMEI number (`sudo screen /dev/ttyACM0 9600`, type `AT+CGSN`, note the number, `^a k`), the Ting [BYOD compatibility checker](https://ting.com/byod/) reported that my laptop would not be supported on the Ting network. Damn.

After scouring the internet for a while, I found the datasheet for the [EM7345](https://linkwave.co.uk/sites/default/files/Sierra_Wireless_AirPrime_EM_Series.pdf), and compared it with Ting's list of [GSM bands](https://help.ting.com/hc/en-us/articles/205428938-Can-I-Bring-My-GSM-Device-to-Ting-Compatibility-and-Unlocking-Guide). It seems my card should support most of the bands necessary for LTE. Hmm. I went ahead and contacted Ting support, and received the reply:

> It does look like the EM7345 supports Bands 1 -5, according to the pdf. It's possible it can work with the GSM SIM, but I can't guarantee it, if the BYOD checker is saying it's incompatible. It looks like it's saying it's incompatible because the IMEI doesn't appear registered in the global GSM database, which means it could work, but not guaranteed.

This seemed promising, so I went ahead and ordered another SIM, and happily plugged it into my machine. I then tried to use a netctl [`mobile_ppp`](https://jens-na.github.io/2014/03/04/archlinux-netctl-mobile-ppp/) profile, using the APN settings [provided by Ting](https://help.ting.com/hc/en-us/articles/205428698-GSM-Android-APN-Settings). *Connection failed*. A quick `journalctl -xe` revealed that the card was reporting errors for pretty much every command.

Remembering that Android (and thus Linux) phones often need to be restarted if you insert a SIM, I decided to try that. Some of the errors disappeared, but it was still complaining about the `ATI` command. Luckily, netctl allows you to provide your own "chat" script to dictate what commands are sent to the modem using the `ChatScript` property. So, I copied over all the commands that were sent to the card in the log, and removed the `ATI` command. Running the profile again showed the process getting further, but this time getting an error at `AT+CGDCONT=1,"IP","wholesale"`. This is the command that actually connects to the APN, so this failing means we can't establish a connection..

After much searching, I came across this handy [AT command reference](https://www.anywi.com/3g/wiki/AtCommandConnSetup), which uses `AT+CGDCONT=2` instead of `AT+CGDCONT=1`. It then says:

> Note that we use PDP context 2, as usually PDP context 1 is used by normal connection.

Out of sheer desperation, I change my chat script to use `2` instead of `1`, remembering something about this card being able to have many simultaneous connections open, and lo' and behold, the connection works! Just like that. My final chat script looks like this:
```
ABORT 'BUSY'
ABORT 'NO CARRIER'
ABORT 'VOICE'
ABORT 'NO DIALTONE'
ABORT 'NO DIAL TONE'
ABORT 'NO ANSWER'
ABORT 'DELAYED'
REPORT CONNECT
TIMEOUT 6
'' 'ATQ0'
'OK-AT-OK' 'ATZ'
TIMEOUT 3
'OK' 'AT'
'OK' 'ATZ'
'OK' 'ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0'
'OK' 'AT'
'OK-AT-OK' 'AT+CGDCONT=2,"IP","wholesale"'
'OK' 'ATDT*99***2#'
TIMEOUT 30
CONNECT ''
```

Hopefully, this will also work on your machine in a similar configuration. Happy surfing!