---
layout: post
title: Yahoo Pipes
date: '2009-11-15 06:14:23'
---

Ever wanted to grab some data from a webpage, or perhaps several, manipulate it in one way or another, and then format access the data through, for instance, JavaScript? Earlier, you would have to write such a script in PHP, ASP, Perl or another scripting language on your web server, and then get the data from that script through JavaScript. This meant you had to run a web server in the first place, and that it would have to support not only fetching data remotely, but also the scripting language you chose to use. And if you didn't know any scripting languages apart from JavaScript, you would be out of luck.

The engineers over at Yahoo came up with a solution: Yahoo! Pipes. Pipes allows you to set up a series of, well, pipes, for your data to go through, each manipulating it slightly, until you have processed your raw data into what you wanted to extract in the format you want it.

Pipes is an essential tool in today's world of mash-ups ( that is, sites that do not have any content themselves, but just collect data from other sources, combine and manipulate them, and then publish the processed data ), because it allows you to do most of the work on a remote server ( Yahoo! ), through a simple drag-and-drop GUI ( Pipes ), and fetch the end result using nothing but JavaScript. You can of course access the data using whatever technology you want, since you determine the output format.

Just to give a simple example of what Pipes can do: Say I wanted to create a feed for my users that contained all my posts, except those that contain the word "task". In order to do this before Pipes, I would have to write up a new PHP script that would fetch all my articles from the database, filter out those with "task" in them, and create a whole new RSS document. Replicating large portions of the code that renders my current feed. Or, I could change my current RSS feed generator so that it accepted URL arguments that allowed filtering by words. All of this would require me both to edit files on my server and make my scripts more complex.

With Yahoo! Pipes, I can simply set my feed as the input source using feed auto-discovery, set up a filter to block items containing "task", and output the resulting elements as RSS XML. Done!

You can see my pipe for doing this at: http://pipes.yahoo.com/jonhoo/nontaskblog

Oh, and did I mention you can publish pipes...? ;)

PS: If you want to fetch the feed form a Wordpress blog, notice that you should not input the feed URL directly, but rather select the source to be "Site Feed", and then input the URL for the front page of your blog.