---
layout: post
title: "Downloading a mms://video stream"
date: '2009-12-13 04:43:24'
---

Have you ever wanted to watch a video online, but due to a slow connection or frequent dropouts, streaming is impossible to watch. In these cases, there is rarely a "Download" button that allows you to download the entire thing and watch it in full when it's done. Evidently, this is a real-world application of Murphy's law.

Here at Bond University, some lectures are streamed and saved for later viewing. These are available to all students from an online interface. The problem is that these videos are streamed (in the proper sense of the word - that is, not that they just play as you download, but as in that the browser has to play back a continuous video stream which causes problems on slow connections since the browser cannot keep up, and has to stop the video all the time and request that the server restart from a previous point in time) even when the lecture has been completed. Even when sitting in the on-campus accomodation, the connection or the server (I don't know which) is too slow to cope with playing these videos in real time, and such, it is a nightmare trying to watch any of these lectures.

The streaming plays in Windows Media Player and uses a protocol called mms:// (Multimedia stream). VLC and Mplayer can both play this as well, but take ages to load for some reason.

In my frustration, I decided to find out how to download the stream so I can play it without delay, and rewind and fast-forward as much as I wanted. Turns out this is not as straight forward as one would expect with streams.

First of all, the file is never present as a file from the server, only as a stream. This means that you cannot download the video faster than the actual length of the video. A two hour lecture therefore takes at least two hours to download. Furthermore, you cannot simply right-click the video and attempt to get the URL and download that because this will only give you a tiny text file with more URLs.

So, here is what you have to do:

 1. Get Mplayer
 2. Go to the page with the streaming video on it and right click the video
 3. Select properties and copy the URL from the window that opens
 4. Open a new tab in your browser and navigate to the given URL
 5. Press Ctrl+S, or otherwise save the page
 6. Open the downloaded file with notepad, you should see something like this: ```[Reference]
Ref1=http://straumod.nrk.no/disk02/Lovebakken/2009-09-11/?MSWMExt=.asf
Ref2=http://10.103.0.56:80/disk02/Lovebakken/2009-09-11/?MSWMExt=.asf```
 7. Copy either of the URLs
 8. Start mplayer with the following parameters: `-dumpstream -dumpfile stream.wmv <URL>`
For those of you who are not familiar with MPlayer and run Windows, here is how you do that:
    1. Press Win+R or press the Start menu and click "Run"
    2. Type "cmd" and press enter
    3. In the new window, type `cd \`, press enter, type `mkdir stream`, press enter, type `cd stream` -- *The previous commands made a new folder in the root of your main drive called "stream"
    4. Next, to run mplayer: type `"C.\Program Files\mplayer` and press tab (with the opening quote at the beginning before pressing tab), type `\mplayer` and press tab again
    5. Write a space, followed by the parameters written above (starting with `-dumpstream`), replacing `<URL>` with the URL you copied in step 7
    6. Press enter and wait
    7. When the program finishes (i.e. the last line says something like `C:\stream>`), you should find the video in the folder "C:\stream" as "stream.wmv".
    8. Rename, play and enjoy!
