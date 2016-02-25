---
layout: post
title: MP4 video in Premiere Pro losing audio after moving to new computer
date: '2009-09-22 12:36:20'
---

As you might have gathered, my roommate and I have been setting up a new computer for the last couple of days. This is quite a beast, which it has to be as he will be working with some heavy video editing on it through, amongst others, Adobe Premiere Pro. 

My roommate has brought with him some unfinished work from back home that he wanted to complete, and so eagerly imported the project onto our new computer and loaded up PP. Naturally, since all the files had been moved, PP required that all the raw files had to be found. This posed no real problem however. What did on the other hand complicate things was the fact that all the imported clips now had no audio!

My friend was naturally afraid he might lose his project and have to do it all over, so he asked me to look into what the problem might be. Though I have no previous experience with Premiere Pro, I began suspecting that a lack of codecs was the cause of the problem. To my frustration though, none of the codecs I installed seemed to have any effect, even though I was certain they would allow the decoding of the given file type ( the files were MP4 ). The files played fine in VLC, but for some reason, Premiere claimed there was no sound in the clips, even though we knew there was. My friend had even edited the files in Premiere on his home computer...

I suspected there might be a version problem as I had not yet updates to the most recent version 3.2.0. And sure enough, after googling around for a changelog I found that the new version did indeed have improved MPEG-4 support. I also found a tip that one should delete all folders ending with .MACC, as this is where Premiere Pro keeps its cache files, which are outdated by the new caching technology employed in the new version. After updating and deleting, everything was running smoothly again, and the sound was where it was supposed to be!

The moral: always update, and delete caches if something that used to work stops to so.

And for those of you wondering, yes, I will be upgrading to CS4 soon...