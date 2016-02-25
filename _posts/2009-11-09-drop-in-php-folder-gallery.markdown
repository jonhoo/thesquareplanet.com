---
layout: post
title: Drop-in PHP folder gallery
date: '2009-11-09 02:57:12'
---

**Update 21/11/09**: The script now supports thumbnails for video and text, as well as timecodes for video and audio. FFMpeg is needed though..

Have you ever uploaded a bunch of images to a new folder at your webserver to share them with others, and ended up with just a listing of clickable filenames? No previews or thumbs of anything..

Well, I've found myself in that position too many times, and decided to create a standalone drop-in PHP gallery file that pulls thumbs from images, videos and text files and displays them in an easily scannable format. The thought behind it was that it should be a single PHP file that could be dropped in the directory and left there without any more work.

The file is not complete, but it does work with images so far, and video and text support is half-way there.

You can see the alpha version here: http://jon.thesquareplanet.com/index.gallery.phps.

To see it in action, see: http://jon.thesquareplanet.com/bond/toga/.