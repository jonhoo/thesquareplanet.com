---
layout: post
title: Jump-starting tricks for aspiring web developers
date: '2009-11-17 02:47:01'
---

So, you want to make websites, do you? Becoming a web developer is both very easy, and very hard at the same time. Mocking up a simple page online with some text and images is easy. Not only are there several WYSIWYG website editors (What You See Is What You Get) out there, but there are also several websites that allow you to create your page online directly through point and click. This is not web development.

Furthermore, if all you want to do is make a design for a web page in Photoshop, you are not a web developer, you are a web designer. Although many web developers tend to be web designers and vice-versa, this is certainly not a matter of implication. A web designer creates a site design, a web developer implements that design - there is nothing more to it. If you create your designs and implement them, you are a web developer as well as a web designer.

There are, of course, several degrees of web development; from basic HTML and CSS to fully-fledged PHP/ASP/&lt;insert programming language here&gt; web applications, but this is not the topic of this post. In this post I intend to give you, as an aspiring web developer, a couple of shortcuts, strategies, tricks and gotchas that I have found during my six years of development experience at the time of writing. This is by no means a complete guide to becoming a web developer, but more of a reference document to get you past the various obstacles browser developers, web standards, faulty documentation and operating systems have put in place to make our life a bit more interesting.

So, without further ado:

# The only 5 tags you'll ever need

HTML and XHTML both contain large amounts of tags. Too many, in fact, for them all to be useful in most cases. Remember, XHTML (and HTML to a large degree) aims to describe the structure of the content, and that is what we have all the tags for. To make the content readily available to screen-readers, text-to-speech engines, search engines and the likes. When prototyping a design, however, you should rarely make use of all of, for instance, the subtle difference between an `<strong>` and a `<b>` tag. In fact, you probably shouldn't even care about the difference between an `<em>` and a `<strong>`; you would probably substitute them both with a `<span>` anyway. Although you should put in the appropriate tags when you begin to develop larger websites, or when you begin to polish the smaller ones, you will find that there are only 5 tags you really need when building an initial design.

 - `<span>` - The fundamental inline element
 - `<div>` - The fundamental block element
 - `<a>` - The link
 - `<img>` - The image
 - `<ul>` - For making lists

Although coding your site using only these tags may be considered bad practice for the reasons explained above, they will in fact get you started quickly and substantially reduce the amount of tags you have to keep in your head when you've just started making web pages.

Due note that these are only content tags, and not the additional meta tags such as `<link>`, `<style>`, `<script>`, and `<meta>` that you will also need to style and animate your site.

# Reset your styles

The #1 reason why your designs do not work when you try to open them in a different browser from the one you initially developed and tested in is because of default margins and paddings. Every browser has its own definition for what padding and margin every element should have if you don't specify any, and consequently, when you move to another browser, all your elements become slightly smaller or larger, and your design collapses into an unrecognizable heap of divs for no apparent reason.

Although reset stylesheets (google it) have recently become quite popular, I often find them unnecessary as they tend to reset too much - giving you more work. Instead, I just a good old rule which simply resets the margin and padding, and nothing more:

```css
* { margin: 0; padding: 0 }
```

Try putting this in your document before you begin, and you'll find cross-browser design becomes a whole lot easier!

# Understand the box model

Way too many web developers don't understand what the difference between margin and padding is, and how these are rendered together with the border of the element. Much less how to calculate the total dimensions of the element. The fact of the matter is that this is essential to being able to create potent web sites. It is also the alpha-omega of many of the CSS hacks you will encounter through your web development career.

A simple Google search reveals several images and sites trying to explain it, and one of the first results explains it quite simply:

[![CSS Box Model](http://www.mandalatv.net/itp/drivebys/css/lib/img/box_model.gif)](http://www.mandalatv.net/itp/drivebys/css/)

Learn it by heart - it will save you much hassle and confusion!

# Face the truth - learn to program

If you're going to make any decent web site, you will have to learn how to program. And I'm not talking about plain ol' HTML, I'm talking of at least Javascript, and preferably a proper server-side language such as PHP or ASP. Javascript allows you to manipulate your site dynamically to make your site a lot more interactive. For instance, you can use it to show a date-picker for an input field, validate form input without going through the server (though for security reasons you should ALWAYS check the data on the server as well), update the page behind the scenes without the user having to refresh the page (AJAX) or make elements on your page fly all over the place. All this power, however, becomes nothing but a fun topping when you consider a server-side language.

Where Javascript deals with the page the user is seeing, the server-side languages allow you to store data the user submits, add dynamic content to your site (This can be anything from a simple "Quote of the day" to allowing users to add articles, list recently added articles and show all articles using the same HTML, allowing the scripting language to fill in the content) and track user sessions (i.e. login and have their own preferences and personalized pages).

Personally, I prefer PHP to ASP, but this is completely up to you - Just learn one because you will have to!

# Use a JavaScript library

Javascript is a wonderful thing, but it also quite awkward. In order to do even simple animations, you need to write a lot of code. In addition, Javascript lacks the broad set of tools that often comes with larger, self-contained languages. There are many libraries out there that attempt to "fix" Javascript in one way or another. Some simply make it easier to manipulate the DOM (Document Object Model) and do animations (jQuery is a typical, and extremely popular library that aims to do this), whilst others go all the way and manipulate Javascript's native methods and objects to make them more powerful, more usable and more flexible. A good example of the latter is the Javascript framework/library MooTools. For larger, more complex Javascript-enabled projects, such a framework is often preferred over the lightweight jQuery equivalents. Pick the tool for the task at hand.

# Know your clients

When developing a website, you need to know what browsers and resolutions you are developing for. If you are making a site for a design bureau, you can usually assume that they will have high resolution screens of at least 1280x1024 or 1600x1400, and you should design your site accordingly. In such cases a fluid design layout might be worth considering to allow your users to utilize the full resolution of their screens. More commonly though, you will be designing for the majority of users, and the majority do not have resolutions of that scale. Too many users still use a 1024x768 resolution, or even smaller, and consequently we have to take this into consideration. Usually, making a page between 900px and 950px wide makes the site viewable for most users, and at the same forces you to avoid extraneous information.

Also, determine whether you should support IE6 or not. This is a major issue as supporting IE6 requires a lot more work than not supporting it because of its blatant disregard for standards and ridiculous implementations of it at times.

A word of caution: If a designer hands you a design with a page-width wider than 950px, don't just scale it down and get on your way! This will not only distort the design, but it will also make all the text smaller which you should avoid at all costs. Make sure all text on your site is easily readable, and try to keep to a maximum of 15 words per line. Anything smaller makes it hard to read, especially on high resolutions!

A second word of caution: Not everyone has Javascript enabled! Make sure you either provided a usable scaled-down version of your site without JS, or that you warn the user that your site requires Javascript. Don't just leave it up to them to find that nothing works..

# Prototype, then validate

If you're told to make a design, make a quick and dirty mock-up. That is not to say it should not look like the design, but that you shouldn't care too much whether your prototype validates or uses the correct tags. Those kinds of things can be changed later if the design is approved. Designers change their mind all the time, and you don't want to spend a lot of time on something they are going to change or remove entirely at the next signpost.

When you're prototyping, however, do try to make the site look similar in all target browsers. The reason for this is mainly because if you make it work in one browser and OK the design, and then, when told to make the site to the design you OK'd, you might find that what you did in that one browser cannot be done in another due to different implementations of the standard. Then what are you going to do? You OK'd the design, remember?

# Follow standards, but not blindly

Standards are a good thing - no question about it. The problem is that at times, it can be a bit too strict. Especially when trying to make your pages render correctly cross-browser.

For instance, IE6 only supports the CSS `:hover` attribute on `<a>` elements, and as such, you may be force to put divs, or other block-level elements, inside an `<a>` tag which will not validate. It will seldom create any problem in any other browser, so theoretically you could just ignore the validation warnings. The problem is that all too many people are concerned about whether their code validates or not. Bottom line is, if it works, and you're confident that it works, and will continue to work cross-browser, the warning is really not that important.

That said, if you can follow the standard and validate your site, do so. It is a form of guarantee that your site design should not be broken by future browsers that might have different rendering engines or follow newer standards. Often, when you're code doesn't validate, it is quite simple to fix the issue. The fix also tends to come at the expense of a degraded experience to IE6 users.... Oh well, that's sad isn't it?

# Plan for security, but delay the implementation

When developing web applications, security should be a major concern. Unfortunately, it is often completely overlooked, or applied seemingly haphazardly; "Oh, I think I'll just put in a striptags here and we'll be good to go!" Not thinking about, and planning, for security can cost you very dearly in the end.

On the other hand, security takes a lot of time and effort to implement, and in the initial stages of web development - when prototyping a new concept or design - you don't really want to bother with that kind of thing. The danger is that once the prototype is complete, you decide to skip the extra work and simply continue work on the prototype with all its hacks, shortcuts and security holes. Don't do it! Instead, plan you security measures thoroughly from the beginning. Do not simply say: "We'll run striptags on all output and addslashes on all input", but set out an abstraction layer which allows you to secure all input and output, not matter where it's going. Decide on security policies and content rules beforehand, instead of patching your old code when someone breaks your system.

This might seem like a lot of work, and it is! It is, however, also very necessary to prevent all sorts of nasty security breaches. The upside of course is that you do not have to implement these security measures when prototyping. In fact, you SHOULDN'T implement them at this stage. Prototyping is about coming up with something workable quickly to see if it works as intended and according to plan. This does not require excessive security precautions. Just remember to put them in when you begin developing the real system.

# Use as few images as possible and merge those you can

Everyone does not have a fast internet connection. In fact, there are still those out there browsing the web on a 56.6kbit modem, and although they are a minority, it should tell us that the excessive use of images and other external media is not exactly taking care of your users. Rather the contrary. That is not to say that you should never use images on a site, in fact images are usually essential to a visually appealing website. The danger is excessive use of media.

A common misconception about external media on web pages is that as long as one uses small images, everything is fine. The truth is that the fewer files the browser has to fetch, the better. Every new request to the server comes with overhead and delay waiting for the server to send its response. Where you can, merge together your images and use [CSS sprites](http://www.alistapart.com/articles/sprites) to display only the part you wish to show. This saves you from the overhead and increases the overall compression rate of your images.

# Don't make a mess - modulate

When you develop websites, it is all too easy to put everything in one file. When prototyping this makes your development speed much higher, but as your system grows it will soon become slow and unmanageable. Instead, try to split your system in to logically separated units. A good place to start is to implement a [MVC oriented framework](http://www.sitepoint.com/blogs/2005/12/22/mvc-and-web-apps-oil-and-water/) for your site.

# Avoid the lazy fallbacks

If you can't understand how to do something the first time around, don't fall back to the easy solutions.

 - Tables are for tabular data
 - Absolute positioning is for overlay windows
 - Frames are an absolute no-no

Instead, try to learn something new, and ask someone who knows more about the problem than you do to help you out.

# When asking for help

If you are not already a programmer, do not make the mistake, as many do, of demanding answers or asking for a piece of code instead of advice. There are plenty of skillful people out there willing to help, but they will not help you if:

 - You do not ask nicely
 - You do not provide source code and other relevant material for them to examine for problems
 - You ask for the complete solution
   - Rather than saying "I need a script that does x", try to make one that does it yourself, and then ask: "I'm trying to do x, and have come up with y. I seem to be stuck because of z. Has anyone got a suggestion about how I might accomplish this?" where y is your source code and z is your problem.

# Essential hacks and gotchas:

In the world of web development, there are some gotchas that are very very common, but are not too often explained. I will try to bring up some of those here:

## The "overflow: hidden" fix:

Say you have the following code:

```html
<div>
  <div style="float: left; height: 200px;"></div>
  <div style="float: left; height: 2300px;"></div>
</div>
```

How tall would you guess the parent div to be? 200? 300?

It will in fact be 0px tall. The reason is that the browser does not count floated elements when considering the height of the element. This "bug" becomes very apparent if you, for instance, try to position something absolutely a certain distance from the bottom within the parent div, because that element would really be position from the bottom of the tallest NON-FLOAT element within the parent.

There are several fixes for this problem, but the most common (and cleanest) method is simply to put the style `overflow: hidden` or `overflow: auto` on the parent. For some reason the browser then takes the floating children into account and correctly sets the height of the parent.

## Absolute positioning

Consider the following code:

```html
<div style="margin: 50px;">
  <div style="position: absolute; top: 50px; left: 50px;"></div>
</div>
```

Where would you say the child div would be positioned in relation to the browser viewport? At (100, 100)? You would be wrong. The correct answer is at (50,50). The reason for this is that absolute positioning is considered relative to the first parent element that has been given a "non-flow" position. That is, any element that has its "position" style set to something else than "static". If no such parent exists, it is positioned in relation to the viewport. A quick fix is simply to set the style declaration "position: relative" on the parent you want to absolutely position the child in relation to. Because relative positioning does in fact not move the element at all unless left and top are specified this means the rest of the page is not affected, and we can get on with our work.

Due note however, that doing this means that ALL absolutely positioned children of the element that receives "position: relative" will be positioned relative to that element. Thus, you cannot have two children elements where one should be relative to the viewport and one relative to the parent.

## Full height column backgrounds

A common design layout is one which has multiple vertical columns (often two or three) next to each other. In the designs, these columns almost always are the same length, with the background color extending to the very bottom of the elements. The problem is that whilst this is very much possible in Photoshop, in HTML an element is only as large as its content or as large as you specify it to be. And unfortunately, CSS does not allow you to specify an element to be as tall as another element. Therefore, if you have multiple columns, and at least one of them has content that will vary in height, you will inevitably end up with the columns being different height. If you then set a background color on each of them, you will notice that the background color is only drawn on the element, thereby making it very obvious that the columns are not the same height.

So, how do you make the columns appear to both be as high as the tallest column? [Faux columns](http://www.alistapart.com/articles/fauxcolumns/). In essence, this approach depends on the parent being as tall as the tallest of the children - which it will be unless we're floating the columns; in which case we can apply the `overflow: hidden` trick. A background image containing all column backgrounds is then applied to the parent and repeated down its entire height. Read the link for full implementation details.

## Working with IE

Let's face it - IE makes our life terrible. With IE8, Microsoft is starting to get it right, but IE7 and particularly IE6 gets a lot of things wrong. Luckily, the fact that they don't follow the standards also gives us several methods of giving specifically tailored instructions to IE. There are two ways of approaching IE specific hacks - the quick, simple way, and the longer but better way:

### The quick fix

Targeting IE6 in CSS: Prefix your selector with `* html `

Targeting IE7 and 6 in CSS: Prefix the attribute with a star (no space between the star and the attribute) - Note that this hack will invalidate your CSS!

### The good fix

Use the Internet Explorer only [Conditional Comments](http://www.quirksmode.org/css/condcom.html)

## Jumping pages

Okay, so you've made you site perfect. It is centered, looks beautiful and navigation is smooth as a kitten's hair. Just one more page to test - the "About us" page with lots of text... As you click the link, your entire page jumps slightly to the left. You try to figure out why, and notice that you now have a scrollbar which means the center of the page has moved, and so, dutifully following your CSS, the browser has moved you page to the new center.

The solution to this annoying problem is to make sure that the scrollbars are always present, but are grayed out when there is nothing below the fold. And how do you do that? Like this:

```css
html {
  	height: 100%;
}
body {
  	min-height: 100.1%;
  	overflow-y: auto;
}
```

## Centering

CSS has many ways of centering, to the confusion and irritation of most developers:

`text-align: center` - This makes inline elements center horizontally in its parent element

`vertical-align: middle` - Should be applied to inline element and [sometimes](http://phrogz.net/CSS/vertical-align/index.html) centers and element vertically if you're lucky (press "sometimes" for more details)

`margin: 0 auto` - Centers a block-level element by setting its left and right margins to the same value. Here, IE of course has to mess up the beauty, and requires the parent to have `text-align: center` in order for it to work. Remember to reset the `text-align` to `left` inside the element!

`position: absolute` - This one requires a bit more explanation. The idea here is that you position an element in the center of another by moving it 50% from the top and 50% from the left, and then move it back by half its dimensions using a negative margin. For example - if you wanted to center an element that is 400x200px within its parent, you would first of all set `position: relative` or similar on the parent (see the Absolute positioning headline further up in this post), and then you would set the following styles on the element itself:

```css
#someelement {
  position: absolute;
  /* Center vertically */
  top: 50%;
  margin-top: -200px;
  /* Center horizontally */
  left: 50%;
  margin-left: -100px;
}
```

If this does not make sense, read it again.

`display: table-cell` - This quite new method relies on using CSSs ability to render any element as if it was a table cell, and then using the vertical alignment property of a table cell to center the content. It is especially good for centering text! [View it here](http://james.gameover.com/index.php/2009/vertically-centring-in-css-without-hacks-and-multi-line-enabled/).

## Use a Doctype

A Doctype is not something one puts in simply to make the page validate, it does actually have an effect as well. In the case of some browsers, the determine whether to render the page according to the standard or not based on the presence of a Doctype. Therefore, put it in!

# Final words

This non-exhaustive list contains my experiences from web development so far, and will probably be expanded upon by both me and hopefully some of you (use the comment field below!). Use it for what its worth, and avoid the pitfalls that are all too easy to fall into when one is new in the field. If you have any questions or comments regarding these notes, feel free to post your comment below, and I'll do my best to give you a proper response!

Happy coding!