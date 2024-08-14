---
layout: post
title: Inline website administration
date: '2009-12-29 15:12:55'
---

Almost all modern websites require some sort of administration, and this usually involves creating a separate administration page where articles can be added and users managed. Lately, I've been making quite a few new websites that will be released in the upcoming year, and all of these have been quite simple sites with a single user and where the administration consists mainly of adding simple news updates and updating page text. For these sites, a full blown administration panel is not necessary, and is also quite inconvenient as the user will have to go back and forth to see the results. So, what are the alternatives?

(Live examples are not available at the moment, but might come later)

# AJAX driven, on-page administration

Here, the user (the person administering the website) is allowed to edit content on the same page as the content through a rich text area in a popup, and the text is then changed afterwards to reflect the users edits.

The simplest, and in my experience most flexible way of doing this is through named fields. Each block of text on the site gets its own unique name, and is linked to a plain text file on the server. In my small site setups, I usually use a structure like this:

```
/
 pages/
  about.inc.php
  projects.inc.php
  bio.inc.php
 api.php
 page.php
 index.php
```

The .inc.php files can either be plain text or contain PHP code. The most important thing is that they have a unique name. The files the usually look something like this (simplified for clarity - remember security and error checking!)

```<?php

// page.php
function printBlock($name) {
    if ( !file_exists ( 'pages/' . $name . '.inc.php' ) ) return;
        echo '<div id="' . $name . '" class="editable">';
        require 'pages/' . $name . '.inc.php';
        echo '</div>';
    }
}

// api.php
require 'page.php';
$action = $_GET['a'];
$block = $_GET['e'];
switch ( $action ) {
    case 'get':
        printBlock ( $block );
        break;
    case 'post':
        file_put_contents ( 'pages/' . $name . '.inc.php', $_POST['content'] );
        break;
}

// index.php
require 'page.php';
?>
```
```
<!-- HTML structure -->
<!-- Then, whenever you're printing a block or page that should be editable, call printBlock -->
<?php printBlock ( 'about' ); ?>
```

Next, you will have to make some sort of JavaScript hook to make all editable areas editable. I like to use a combination of [CKEditor](http://ckeditor.com/), a simplified version of lightbox and jQuery so the end result looks something like this when a user double clicks on a box with the editable class:

![Popup when editing text block](/blog/content/images/2015/05/popup-on.jpg)

Upon saving, jQuery sends a AJAX request to the api.php file with the updated contents, and also changes the contents of the block on the page using the .html() method on the element with the same ID as the block name.

# In-line administration
On some sites, popup boxes simply won't cut it. In fact, they might even become a bit cumbersome when working with news articles and such where you might want a live preview of the article as you're typing it. Earlier, one had to have a rich text editor with a "Preview" button, but now we have a much better tool available: `contentEditable`. This awesome attribute allows you to tell the browser to allow the user to change the contents of an element on your page at will. Consider these screenshots that illustrate adding a new news post on a page utilizing this attribute for administration:

![Before adding the article](/blog/content/images/2015/05/inline-pre.jpg)

![Adding a title](/blog/content/images/2015/05/inline-title.jpg)

![Editing the post body](/blog/content/images/2015/05/inline-body1.jpg)

![After saving the new post](/blog/content/images/2015/05/inline-post.jpg)

As you can see, this is a very simple way of creating and editing posts - and immediately seeing how it would look on the page. The major drawback is that you cannot easily accept rich inline content such as images and video, or even simple text formatting. On the other hand, such features often clutter the articles anyway. On this site, I have overcome this by allowing file attachments that are placed beneath the article based on their type (images are shown in a gallery strip, videos are embedded, etc.) Text formatting is achieved through a [markdown](http://daringfireball.net/projects/markdown/)-like syntax handled by JavaScript. There is no rich text logic in the backend.

Using `contentEditable` is quite simple. All you have to do is use JavaScript's `setAttribute`/`removeAttribute` functions on any element you want to be editable. Set the attribute to true when you want it turned on, and remove it when you want it off. Apart from this, everything is quite straight-forward and very similar to the previous method of popup administration. JavaScript sends the new content to the backend, which saves it and returns the HTML rendering of the content as it would be displayed when loading the front page regularly. JavaScript then swaps the editable post area with the HTML from the server and disables editing on it.

# Rounding up
Both these techniques provide quite intuitive and easy-to-access administration equivalents to classical admin-panel interfaces. They are not especially complex to build either, though they provide the user with a more comfortable and usable way to manage their sites. If you have any questions regarding these techniques, don't hesitate to use the comment field below or e-mail me at jon `you know what goes here` thesquareplanet `and you know this one as well` com.
