---
layout: post
title: Browse the web with PHP
date: '2009-12-16 07:59:09'
---

Ever so often, you come across a website that you would like to check regularly. Usually, this website is placed behind some sort of login, and therefore, you think, you might just as well forget it. A while ago, I found myself in the same situation. My university in Oslo published grades online, but gave you no warning when the exam results where published, so you had to check every now and then to see if you had any new ones. I figured that this was a bit bothersome, and wanted to find a way around it.

There are several scripts and browser plugins out there that can check a page for updates on a regular basis, and notify you when something changes. The problem is that this site required you to log in first by submitting a form, and then navigate to the relevant page. I therefore decided to write a PHP class (or actually two) that would allow me to browse the web as through a browser; submitting forms and clicking links.

The result was the two classes, [Browser](http://www.phpclasses.org/browse/package/5450.html) and [RemoteForm](http://www.phpclasses.org/browse/package/5449.html). The latter is a class that takes a form and parses out any input fields, selects and textareas and their respective default values. It then allows you to set values for these fields and submit the form - returning the resulting URL. The Browser class is one layer above, and depends on the RemoteForm class for handling form submission. It allows you to start a browser session and then navigate by simulating clicks on links through XPath selection.

See how simple it is to submit a search form on Wikipedia:

```php
<?php
require 'browser.class.php';
/**
* The long way to the PHP Reference Manual...
*/
/**
* New browser object
*/
$b = new Browser ( );
/**
* Navigate to the first url
*/
$b -> navigate ( 'http://en.wikipedia.org/wiki/Main_Page' );
/**
* Search for php
*/
$b -> submitForm (
$b -> getForm ( "//form[@id='searchform']" )
   -> setAttributeByName ( 'search', 'php' ),
'fulltext'
)
    -> click ( "//a[@title='PHP']" ) // Click the PHP search result
    -> click ( "PHP Reference Manual" ); // Click the link to the ref
echo $b -> getSource(); // Output the source
```