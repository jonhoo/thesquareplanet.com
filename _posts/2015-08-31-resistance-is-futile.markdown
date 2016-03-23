---
layout: post
title: Resistance is futile
date: '2015-08-31 00:00:24'
shared:
  Hacker News: https://news.ycombinator.com/item?id=10148568
  Twitter: https://twitter.com/Jonhoo/status/638142143329107968
---

Recently, online video streaming sites have started to dominate the scene when it comes to watching TV shows online, and is slowly surpassing the use of torrents for a large number of non-technical users. Sites like [Project Free TV](http://projectfreetv.so/) and [Watch Series](http://thewatchseries.to/) index this content, providing users with lists of seasons and episodes, along with multiple mirrors for each video.

However, while these services are easier to access for the average user, they also come riddled with ads, and occasionally more sinister things. A number of projects exist that try to tackle this problem ([youtube-dl](https://rg3.github.io/youtube-dl/) and [quvi](http://quvi.sourceforge.net/) are perhaps the most well-known) by having technical users contribute scripts that extract the raw video URL from a video site URL. A while ago, I even decided to write my own, [streamsh](https://github.com/jonhoo/streamsh), simply to see if this could be done purely in bash (well, with some help from [pup](https://github.com/ericchiang/pup)).

I've been very happy with this solution, which lets me access streaming video from these sites entirely from the comfort of the command line. Over time, the video sites change in order to prevent exactly this kind of content scraping, but getting around the "protections" they put in place is usually no more than a couple of minute's effort (JavaScript obfuscation, for example, keeps popping up, despite being [woefully insufficient](https://github.com/jonhoo/streamsh/tree/master/unval)). However, lately I've been starting to see a new kind of protection that took a while to tear apart. What follows is a recap of that journey.

In order to understand this protection mechanism, we first need a primer on how the video players used by these sites work. At their core, the sites all embed a Flash object containing a video player in your browser, and they need to tell that player where to find the desired video file. Most of the sites use [JW Player](https://github.com/jwplayer/jwplayer), which is (mostly) free and open-source, as their go-to video player. JWP is started quite easily from JavaScript using something like the following code snippet:

```javascript
jwplayer("flvplayer").setup({file:"http://site.com/video.mp4", …});
```

This tells JWP to spawn a new player in the element on the page with the ID "flvplayer", and load and play the file located at `http://site.com/video.mp4`. Usually, once you find that code, you've won — simply extract the URL and download it using `curl` or `wget`. But recently, I've started seeing code like this:

```javascript
jwplayer("flvplayer").setup({file:"349f9dd3ae2c8…6dbf9db06e6c4", …});
```

That doesn't look much like a URL. If anything, it looks like hex — there are no characters outside the range `0-9a-f`. A quick pipe through `xxd -r` reveals just binary garbage, so there's obviously some kind of encoding or encryption going on... Initially, I decided it wasn't worth the effort to try and circumvent this, so I started using other streaming sites instead. However, as time passed, more sites migrated to this weird URL obfuscation scheme, so I decided it was time to give it another go.

The starting point for any online streaming-related problem is the player. You know that the player *must* eventually know the URL, so that it can tell the browser what file to download. This means that the algorithm for converting this weird string to a URL must be hidden *somewhere* in the SWF. The HTML sports little more than an innocent-looking `<embed src='/player/player.swf'>`, which looks like it's a pretty stock build of JWP, but reading further in the call to `setup()`, reveals `plugins:{"/player/asproject.swf":{}, …}`. That's interesting. Let's try running that through a [Flash disassembler](http://www.showmycode.com/).

A quick glance at `asproject.as` reveals the interestingly-named function `decodeHash` near the bottom of the file. It calls `getDecryptValue()`, but it doesn't seem to be defined anywhere in `asproject.swf`, nor in the source of JWP. Some further reading reveals that a third SWF is loaded: `this.myUrl + "obc.swf"`. Let's try our luck there instead…

Bingo! A disassembly of `/player/obc.swf` gives us `decryptor.as`, which uses the (now discontinued) AS3 crypto library As3Crypto from [hurlant.com](http://crypto.hurlant.com/docs/). Not only that, but the source code also gives us both the hex value of the decryption key (the concatenation of `h1` through `h5` at the top of the file), and the encryption scheme (`simple-aes-ecb`). Plugging those into `openssl`, we should now be able to decrypt the file hash from `setup()`:

```
$ echo -n "349f9dd3ae2c8…6dbf9db06e6c4" | xxd -r -p | openssl enc -d -aes-128-ecb -K a949376e37b369f17bc7d3c7a04c5721
bad decrypt
140044748175000:error:06065064:digital envelope routines:EVP_DecryptFinal_ex:bad decrypt:evp_enc.c:529:
http://50.7.120.122:182/d/yfsaqhrjljrwuximwi7h54au46dsbvyasgljthk7pgvdvj26d6nsje
$ curl "http://50.7.120.122:182/d/yfsaqhrjlj…26d6nsje"
wrong ip
```

Uh oh, that's no good… What did we do wrong? I'll save you the headache; it turns out that we actually need to pass in the data with a newline at the end for the decryption to work correctly. I have no idea why. Like this:

```
$ (echo -n "349f9dd3ae2c8…6dbf9db06e6c4" | xxd -r -p; echo "") | openssl enc -d -aes-128-ecb -K a949376e37b369f17bc7d3c7a04c5721
bad decrypt
140605830448792:error:0606506D:digital envelope routines:EVP_DecryptFinal_ex:wrong final block length:evp_enc.c:518:
http://50.7.120.122:182/d/yfsaqhrjrw…d6nsjeal/video.mp4
$ curl "http://50.7.120.122:182/d/yfsaqhrjrw…d6nsjeal/video.mp4"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 70.1M  100 70.1M    0     0   393k      0  0:03:02  0:03:02 --:--:--  372k
```

We still get the "bad decrypt" error (if you know why, please ping me), but the resulting URL seems like it's valid! Yay us! Now we can yet again enjoy those TV shows that haven't gotten with the program and joined Netflix yet, and we can do so entirely without Flash or ads. This trick has also been pushed to [streamsh](https://github.com/jonhoo/streamsh/blob/master/tricks/jwplayer.sh).

As a concluding note, these defensive measures are all pretty pointless. Some degree of obfuscation and limited-lifetime IP-bound URLs are probably useful to avoid abuse and hotlinking, but in the end, the client has to see a plain URL. While [EME](https://en.wikipedia.org/wiki/Encrypted_Media_Extensions) might spell an end to this kind of streaming freedom, we might hope that it will at least provide us with ad-free and Flash-free streaming as more mainstream content becomes available on (reasonably priced) paid streaming sites. Time will tell.
