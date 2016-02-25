---
layout: post
title: Developing for the modern web
date: '2009-12-17 09:57:25'
---

*Update 2015-05-04: Note that much of the advice here will become outdated with HTTP 2, where there should be little to no performance degradation when serving many smaller files, and where compression might be on by default!*

Web development today is a constantly struggle between three major stakeholders: the customer, the designer and the developer. The customer tries to push through his or her ([often distorted and silly](http://inspectelement.com/articles/the-funny-and-bizarre-world-of-client-requests/)) mental image of the website, the designer wants to be original, creative and fancy creating lots of intricate designs with fancy visual effects, and the developer who attempts desperately to explain to both the customer and the designer why what they're doing is a bad idea (heavy background images, crammed pages, no whitespace, confusing visual effects...). The developers aren't all good either though - They tend to put in as many fancy tricks and solutions in the final product as they can, often resulting in exotic bugs in various browsers and usually ungraceful downgrading™. In all of this, one stakeholder is often wholly forgotten, even though it is probably the most important one; the users.

Users often don't know the first thing about how the web works. They don't care whether the site is optimized for Firefox, Internet Explorer, Chrome or Safari (in fact, they probably [don't even know what a browser is](http://www.youtube.com/watch?v=o4MwTvtyrUQ...)) The users want a site that is visually appealing, but not distracting - informative, but not cluttered - clear, but not over-simplified - and most importantly, one that is responsive. When a user does something, they should begin to see something happening [within .1 seconds](http://www.useit.com/alertbox/timeframes.html) to feel as though they aren't being slowed down by the site itself. Furthermore, the total loading time for whatever action the user initiates should be less than a second for the user not to fall out of his or her "flow". Way to many websites violate these simple rules, causing the site to feel unresponsive to the user, and the users are likely to jump to the next site on their list.

In this post, I hope to show you how to make your website faster - mainly through optimizing the initial page load. In order to do this, there are three steps that need to be taken: Combine, Compress and Communicate. Repeat after me: Combine, Compress and Communicate.

### Combine

Many developers seem to think (albeit erroneously) that many small files are better than few large ones. This might seem intuitive since a smaller file downloads faster than a large one, and you would think they could all be gotten out of the way quicker. The truth is quite different. Due to limitations of the HTTP protocol, the browser has to initiate a new request to the server for every single file, causing quite a bit of overhead when having to download several files. Also, modern browsers limit the amount of simultaneous downloads to 6, meaning downloading all of your small files will go even slower. Add to this the sequential nature of JavaScript, and the fact that the browser stops loading the page once it hits a JavaScript piece (external or not), and doesn't continue loading until the JavaScript file is finished downloading and has been interpreted.

Therefore, you should work to combine as many of your files as possible. Don't jump to put all your scripts and styles inline, however (you will understand why in Communicate). Instead, you should attempt to combine all your CSS files into one, all your JavaScript into another, and all your images into a third. Ideally, you should need no more than three external files on your site. So, how do you go about doing this?

#### CSS and JavaScript

Combining CSS and JS files shouldn't itself be a problem.. Open up a text editor, copy-paste all of your CSS or JS into that file, save it and upload. You should probably still keep the separated files for readability though. Of course, modern web applications are usually a bit more complicated. For instance, you might have a stylesheet that is only included on sites with ads on them or a JavaScript file that is only needed on your frontpage. In these cases, your should look into using a combinator. One of the best sites describing the techniques of combining is [this one](http://www.artzstudio.com/2008/08/using-modconcat-to-speed-up-render-start/). The mod_concat plugin for Apache2 provides several advantages over traditional scripting approaches especially with regards to communication (as will be discussed later)

#### Images

All your images should be done as sprites. Ideally, you should even be able to put every single image on your site into a single png image. Do this, and you will substantially reduce the loading time of your site. For an introduction to CSS sprites, have a look [here](http://css-tricks.com/css-sprites/).

### Compress

All your CSS and JS files should be compressed to reduced overall download size. Again, it is usually a good idea to keep the original, uncompressed versions of the files, and re-compress the files whenever you change them. For CSS, I recommend the [YUI compiler](http://www.refresh-sf.com/yui/). It does JavaScript as well, but Google's recently released [Closure Compiler](http://closure-compiler.appspot.com/home) seems to be even more effective at compressing it. With the Closure Compiler, you can also select the advanced compiler which will decrease the total file size even more, but will mess up your files' external API. This means that any functions you define inside your files won't be available from the outside by the same name. The internal workings of the file will be preserved though.

Apart from minimizing the files, you should also compress them using something like GZip which is natively supported by several browsers. To see how to do this automatically with Apache2, have a look at [this guide](http://www.cyberciti.biz/tips/speed-up-apache-20-web-access-or-downloads-with-mod_deflate.html).

### Communicate

OK, so all of your files are combined and compressed, and you've never seen the CSS and JavaScript download so quickly. How can it possibly go any faster? Quite simple - by preventing the browser from having to download the files at all. Modern browsers include a lot of caching technology to prevent them from downloading unnecessary data from the server. The problem is that many web servers do not communicate properly the states of the files, and the browsers can thus not determine if a file has changed or not; and therefore they download the file just to make sure. So, what should you do?

First of all, you need to tell your web server to send out as much data as possible about your file. This especially applies to dynamic files such as those created by PHP. Have a look [here](http://articles.sitepoint.com/article/caching-php-performance) for a more thorough discussion of this topic.

Second, files that are GZipped by Apache don't always get an expiration date, causing the browser to re-download the file on every page load. To overcome this problem, have a look at the first answer on [this page](http://serverfault.com/questions/21447/apache-gzip-configuration)

### Final thoughts

In the course of this post, I hope I have given you an overview of what can be done to speed up the loading time of web pages, and enough pointers to keep you going in your quest for the best speed your website can achieve. This is an ever-expanding topic, and new techniques are always appearing, so you should attempt as best you can to keep up to speed (pun intended) on the newest advances in the field.

Happy speeding!