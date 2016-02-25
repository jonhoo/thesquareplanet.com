---
layout: post
title: Handling swipe and click with JavaScript
date: '2012-03-26 14:28:33'
---

So, you've got a list with overflow:hidden, and you want to make it scrollable with touch?
And perhaps you don't want to include a library such as [iScroll]((http://cubiq.org/iscroll-4), you just want simple scrolling with as little code as possible.
Perhaps you even stumbled across the fairly simple [solution](http://chris-barr.com/index.php/entry/scrolling_a_overflowauto_element_on_a_touch_screen_device/) proposed by Chris Barr on his blog, so you start using it (replacing all .pageY with .pageX for horizontal scrolling), and your content scrolls like never before!

You then try to click one of your elements. And nothing happens. You try, and try, and try to no avail. Then you give up, throw your hands in the air, yell "I knew it wasn't that easy", and use iScroll.

Before I hand you the solution on a (somewhat) silver platter, let me tell you what's causing the problem. Notice the `event.preventDefault();` Chris has in his event handlers? These are what break your onclick handler (or href), since they tell the browser not to do whatever it would normally have done when, say, a touch is initiated on a clickable element. Unfortunately, they also have to be there, otherwise your phone would, helpful as it is, try to scroll the entire page.

So, how do we solve this? Well, it's quite simple really. Think about it. What is a click? It's a tap. And what's a tap? It's a touch motion that does not include any movement.

Without further ado, the solution can be found in [this gist](https://gist.github.com/2205417).

The only additions to Chris' code is that we monitor whether touchmove has been triggered since the last call to touchstart. If it hasn't then it was a click.
What you decide to put inside the if in touchend is what you'd normally but in your onclick handler. If you're using jQuery, you would typically use `$(e.target).closest('a')` or something similar to get the element that the onclick event would normally have triggered on.

Enjoy!

**Update 2012-04-26**: Changed the code to delay handling the click in case the user just paused while swiping.