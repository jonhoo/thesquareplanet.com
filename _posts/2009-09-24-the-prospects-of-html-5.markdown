---
layout: post
title: The prospects of HTML 5
date: '2009-09-24 07:59:20'
---

As a webdeveloper, feature additions and updates to commonly used libraries and languages are always exciting. Unfortunately, there is one core language of web development which has not received a proper update in years - HTML. Sure, we had XHTML, but in my opinion, that was more of a structural change than it was a rewrite of HTML. XHTML merely enforced a XML structure as well as standardize the elements used for various types of content.

This is all about to change with the development of HTML 5. HTML 5 is currently only a W3C draft, but some of its major features are already implemented in various browsers. As supposed to XHTML, HTML 5 aims to bring HTML into this century, and make it more flexible in order to satisfy the needs of today's developers and users for multimedia content, AJAX-based user interfaces, geolocation and desktop application-like behaviour.

### Brief overview of new features

HTML 5 provides a plethora of extensions and changes to traditional HTML, and to get a complete overview I suggest your read the [W3C Draft](https://html-differences.whatwg.org/) which makes for very interesting reading once you can look past the RFC style. There are however a couple of features that are especially interesting:

 - The whole language will be based on DOM definitions, which makes the border between Javascript and the HTML quite a lot thinner.
 - HTML 5 attempts to discard the remaining style-based tags of HTML, as well as remove support for frames and other "ugly" practices
 - It is also developed to accommodate the way modern websites are structured, and make the structure more available to computer interpretation. For instance, instead of using divs for all sorts of site content, HTML 5 introduces specialized tags for the different sections of a webpage such as:
   - `<header>`
   - `<footer>`
   - `<article>`
   - `<aside>`
   - `<menu>`
   - `<section>`
 - A new way of handling element contexts ( i.e. moving away from the differentiation of inline and block context )
 - Native Drag-and-drop and Copy-Cut-Paste APIs
 - Undo history and editable content
 - Support for geolocation-enabled applications
 - Native multimedia tags and players to avoid the format challenges developers currently face when adding multimedia to their sites

There are several more, but again, I recommend having a look at the W3C Draft for a more in-depth description.

### Multimedia

HTML 5 introduces two especially interesting tags: `<audio>` and `<video>`. These tags are quite simple, but very powerful. They both require nothing but a source file to play, but they not only provide a native, integrated player for the given content format, but it also provides a scriptable API to manipulate the controls and playback from a scripting language like Javascript. No more proprietary or hard-to-customize flash players with limited format support!

### Draggable, copy-paste and undo

The draft also introduces two new concepts that are still under heavy debate with regards to the implementation: [Native drag-and-drop support](http://www.w3.org/TR/2008/WD-html5-20080122/#dnd) and a copy-paste API as an extension of the draggable support ( since according to the draft, you "drag" the copied content into the clipboard, and "drop" it back from the clipboard ), and an [undo-redo history API](http://www.w3.org/TR/2008/WD-html5-20080122/#undo).

The draggable support will remove the need for a third-party drag-n-drop library such as jQuery-UI, mootools or Prototype, and let the browser deal with this directly. Not only will this probably provide a smoother user experience, but it will most certainly enable you to build more flexible UIs since the W3C Draft dictates a lot of event triggers and intermediate controls that let you handle the dragging in high detail.

Undo history is probably the most controversial feature of the W3C Draft as no good standard definition of it has been found. From the draft one can nonetheless extract some useful indicators of how the final feature will work.

According to the current definition, the undo/redo history will store all changes to the website DOM, and allow the user to revert to previous version of the page. Most probably, it will also allow control hooks that enable you to do server actions when the user walks backwards or forwards through the history.

So, you might ask, why would I need DOM history? Well, both because you will now be able to use [AJAX page loading](http://thybag.co.uk/index.php?p=Tutorials&amp;ind=44) without [breaking the back button](http://www.isolani.co.uk/blog/javascript/FixingTheBackButtonThatAjaxBroke), but also because of the new attribute `contentEditable`:

### Editable HTML content

HTML 5 brings a seemingly innocent attribute called `contentEditable` which, when enabled, allows the user to directly manipulate the DOM through for instance a rich-text editor, or however the browser developers decide to implement the feature. This makes for a whole new type of webpages where you can let the user completely redesign the site to his or her own liking, and where the changes may be saved for later use. And just imagine the advantages with regards to rich-text editing for blogs, articles, or indeed any other web content.

### Geolocation

A new API has also been deviced to encourage the use of websites for portable devices or other GPS enabled computers. The API allows the website to read the users current location, as well as any updates to this. This will also enable developers to build applications that are location-sensitive, and give you data relative to your location.

### Other scripting changes

With HTML 5, W3C has also had a look at commonly requested features and features implemented by the major Javascript frameworks. This has lead to the standardization of certain long sought-after components like:

 - `getElementsByClassName`
 - Input fields with native validation support ( type="date, datetime, email, url, telephone...", the "required" attribute, etc )
 - Support for unlimited additional attributes for internal use as long as they are prefixed by data-
 - Independent inputs - input fields may be placed outside a form tag, but still linked to the form itself
 - Client-side storage - a simple key/value-pair local database accessible through Javascript which will probably bring a great deal more offline web applications
 - The progress/meter tags - A way of visualizing progress or numerical values to the user without the use of ugly table/css hacks.
 - Anchor ping attribute - This new attribute allows you to specify a list of URLs that should be pinged if the user clicks a link to avoid redirects to log link clicks, and make them asynchronous instead.
 - The canvas tag

The `<canvas>` tag is also a very promising new feature, that enables developers to draw directly to the users screen. This makes way for Javascript-based games, handwriting-enabled applications, Javascript movies, and who knows what else. If you're running Chrome ( Firefox and Opera also work, but cause a great deal of lag ), you can have a look at the kind of things that can be done at http://www.chromeexperiments.com/.

### So, when can I use it?

Since HTML 5 is aimed at being backwards compatible, you can start to implement it today, though many users will probably not receive the full experience of the markup in a while. A good reference might be molly.com's [A Selection of Supported Features in HTML5](http://molly.com/html5/html5-0709.html). You might also want to make use of the Javascript HTML 5 detection library [Modernizr](http://www.modernizr.com/).

### What about CSS 3?

CSS 3, however amazing it might be, is not a part of the HTML 5 standard. Also, support for this the CSS 3 **Draft** is not very broad either. I will probably post an overview of it at a later date as well.

### Further reading and sources:

 - http://dev.w3.org/html5/html4-differences/
 - http://www.smashingmagazine.com/2009/07/16/html5-and-the-future-of-the-web/
 - Geolocation: http://dev.w3.org/geo/api/spec-source.html
 - http://www.w3.org/TR/html5/forms.html
 - http://www.w3.org/TR/html5/video.html
 - http://www.w3.org/TR/html5/semantics.html
 - The full spec: http://www.w3.org/TR/2008/WD-html5-20080122