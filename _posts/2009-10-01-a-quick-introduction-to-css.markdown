---
layout: post
title: A quick introduction to CSS
date: '2009-10-01 07:41:11'
---

Before I dig into the CSS 3 draft, I am going to give a quick introduction to the basics of CSS for those who do not feel entirely comfortable with the apparent complexity of Cascading Style Sheets;

First of all, what is CSS? CSS is a programming language, or perhaps more of a file syntax, for styling for XML and HTML.

But can't I do that with HTML tags? Well, you can, but there are two reasons why you should not do that: (1) The standard dictates that you should separate the styles from the content and structure, and (2) Not all browsers support the same HTML tags, and style them in the same way. CSS gives you a powerful toolkit for making the page look exactly how you want it to.

First of all, you must realize that with the versatility of CSS comes complexity, and if you start your CSS career by digging into the stylesheets of a large site, you will most likely be very confused at first. Therefore, let us start with the basics:

# CSS from the bottom up

There are several ways to style your web pages through CSS: inline styles, internal style definitions and external stylesheets, where the last one is the recommended and most used one. I will come to why later.

Inline styles are styles set directly in one element through the `style=""` attribute like this: `<span style="color: red;">` ( this would make the encapsulated text in the span red )

Internal style definitions are defined inside `<style type="text/css"></style>` tags in the HTML or XML document, and uses selectors (  I will explain the syntax of CSS later ) to style given elements.

And external stylesheets consist of "pure" CSS in an external file that is included through a link tag as such: `<link rel="stylesheet" type="text/css" href="stylesheet.css" />`.

I encourage the use of external stylesheets, because they allow you to share the same styles between several pages ( they all just need the same link tag ), and make it very easy to do site-wide design changes by only editing a single file. Secondly, external stylesheets can be compressed quite easily, and several stylesheets can be combined on any given page to provide styles from different sources.

# Getting down and dirty - selectors and styles

The syntax of CSS itself consists of two parts, selectors and styles. The selectors tell the browser what elements the styles should apply to, and the styles tell how the elements should look.

## Selectors

CSS primarily has six types of selectors, though this will likely be expanded in the future:

 - element
 - id
 - class
 - descendant
 - attribute
 - pseudo-classes

The element tag is the simplest one, as it simply specifies the type of the elements that should be styled, and applies the styles to all of the elements on the page that matches. One such selector could be something as simple as `p` or `strong` . These two selectors would match p-tags and strong-tags respectively.

Next, we have the id selector. This allows you to apply styles to only the element with a given value in its ID attribute. The id selector is also quite simple; a hash sign ( # ), followed by the id of the element you wish to style. For instance, `#myelement` would match the element on the page with the id "myelement"

The class selector allows you to apply styles to a group of elements on the page that share the same HTML class on your page. In syntax, it is similar to the id selector, but it uses a period ( . ) instead of the hash sign ( # ). Matching all elements with the class "myclass" would thus be done by using the selector `.myclass`

Descendant selectors allow you to tell the browser to only apply styles that match a given selector inside an element that matches another. If I wanted to style all anchor ( a ) tags inside elements with class "linkme", I could do this in CSS by using the decendency selector ( it is not really a selector, but more of a way to combine other selectors ) which is, quite simply, a space. The correct selector would then be `.linkme a`. Not too bad is it?

We can also filter on the contents of specific attributes in CSS, though not all browsers support this feature. Specifying attribute selectors is a bit trickier than the previous selectors, but they are very powerful once you learn how to use them properly. An attribute selector consists of an attribute ( such as href, rel, title, class or id ), a comparison operator, and a value, contained in a pair of square brackets []. There are several comparison operators, but the most commonly used ones are:

 - `=`, the contents of the attribute has to match exactly the value you give
 - `~=`, at least one of the space-separated words of the attribute has to match the value you give
 - `|=`, same as above, but hyphen-separated
 - no comparison operator or value, the attribute has to exist on the element

The value may be encapsulated with double quotes, but this is not required. If I wanted to match all anchor elements linking to youtube for instance, I could do the following: `[href=http://www.youtube.com]`

And finally, we have the pseudo-class selector. This allows you to select only elements that have a certain property or state. Say you wanted to style a link only when the user hovers over it, you would use the `:hover` pseudo-class selector to accomplish this. There are several of these, and more will come with CSS3, and support varies greatly between browsers, but the most common ones are:

 - `:hover` - when the user hovers over the element
 - `:visited` - if the user has visited the element ( mostly used on links )
 - `:first-child` - matches only if the element is the first child node of the parent
 - `:first-letter` - matches the first letter of the text content of the element

If we wanted to turn a link bold when it is hovered over, we would typically do something like the following: `a:hover { font-weight: bold; }`

There are two things that might confuse you with my last example, one is the fact that I put an a before the colon, and the second is the statement `font-weight: bold`. The last one I will come back to when discussing styles, but the first one deserves an explanation straight away.

A common issue one might encounter is, like above, that you want to style the hover styling on all anchor elements. However, if we had simply written `:hover`, that would match all the elements on the page, which would mean that everything on the page would turn bold when hovered over. Therefore, CSS allows you to chain several selectors together to allow for more specific filter. This is done by simply appending one selector to another without any space in between. The above example therefore translates to " select all a elements when they are hovered over", whereas `:hover` would mean "select any element that is hovered over". See the difference? There are no limits here, and you could even do something like this: `a.coollink:hover:first-letter`, which would style the first letter of all anchor elements with the class "coollink" when they are hovered over.

If we describe this chaining as a "and" operation, since it requires that the element matches all of the chained selectors, we soon find ourselves in need of a similar "or" operator. Luckily, CSS provides this as well, the comma. If I wanted a style to apply to, for example, all anchor elements and all strong tags with the class "styleme", I could do that like this: `a, strong.styleme`. *Due note: The comma is an absolute separator, and as such, `div a, strong` would not match all a's and strong's inside a div, but rather all elements that are either a's inside a div OR are simply strong tags!*

## What about the styles?

As mentioned, CSS consists of styles and selectors, and whereas there are quite few selectors, there is a vast amount of styles.

A style takes the form of `attribute: value;`, and you may specify multiple styles for each selector. The way the styles are specified follows the following syntax:

```css
selector1, selector2, selector3 {
  attribute1: value1;
  attribute2: value2;
  attribute3: value3;
  /* Comment: etc... */
}
```

For a full list of CSS attributes, I suggest you have a look at the following page: http://www.w3schools.com/CSS/CSS_reference.asp, but I will mention a few of the most common ones:

 - `font-family` - Specifies the font(s) to use for the specified elements
 - `font-size` - The size of the text
 - `color` - The text color
 - `background` - Background styling ( color, images, etc... )

Again, the styles are so diverse and plentiful that the best way to learn is by deciding on a design, and then simply try to create it from scratch, and learn by looking things up as you go. Experience is the best teacher one can have.

So, there you have it. A quick and dirty introduction to CSS that has hopefully provided some insight into the wonderful world of website styling. The only thing that remains now is to start using it, and to set challenges for yourself that require a bit more knowledge than you have. That way, you will be forced to look up how other have done it, and expand your knowledge much faster than any tutorial can do.