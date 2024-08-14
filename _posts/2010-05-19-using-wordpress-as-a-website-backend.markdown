---
layout: post
title: Using WordPress as a website backend
date: '2010-05-19 10:59:28'
---

How often have you found yourself creating a great new website design for a friend, family or a client, just to realize after all your HTML and CSS is done that the thing will need an administration panel? Way too often, the administration comes as an afterthought, and thus it ends up being incomplete, hard to use or in some cases absent. Two months down the track you end up being contacted again to do some "site updates", and these just keep coming.

Making a good administration panel takes a bit of work, and it takes planning to ensure that the client can update the parts of the site as he/she wishes, and more importantly, that your interface gets all the information it needs. If your design has a thumbnail for every post, your administration panel has to provide the opportunity to upload an image and attach it to a post.

For years, I have been making these admin pages myself, until I read a post on WordPress custom themes. This post was on how to write a theme for WordPress, but it hinted at the possibility of having a standalone site that used WordPress as its backend, thus providing a full-fledged, well designed and familiar administration interface to any site. At first I was skeptical to the idea because I thought WordPress was way to inflexible to allow for the variety of pages I make. I was wrong. You see, if you really thing about it, all you need to make most websites are two things: Posts in categories and dynamic text/HTML blocks.

To give you an idea on how flexible WordPress is, and how it can be used, consider the following website which I am currently working on. The site is for a sound production company, and will contain the following:

 - Short posts giving updates on what the studio is working on at the moment. These have to have a short text to be shown on the front page, a feature image and a rich-text full article.
 - An image feed showing images of the sound studio
 - A page with the various projects the studio has completed. Each project has an image, a description and one or more music tracks. Each track has two variants, a streaming-quality MP3 and a high-quality WAV.
 - An about page with two separate columns, one on the sound designer, and one on the company
 - A list of previous clients with a short description and a link to the client's website

At first, this seems outside the scope of WordPress which only deals with Posts and Pages, but let's have a closer look.

The posts are clearly just regular WordPress posts. Let us put them in a category called "Frontpage".

The image feed is just a stream of images. We here have two choices, use WordPress' media library, and attach all images to be shown in the feed to a static page, or use a flickr stream. I opted for the latter, but WordPress could have handled this fine!

Each music project can be a blog post (you heard me right) in the category "Projects". We can then attach images and songs to the post using the WordPress media library. The two versions of each music file can be given the same name, and we can use the MIME type to distinguish between them.

The two text blocks 0n the about page can be two WordPress Pages (let's call them 'designer' and 'studio')

Finally, the list of clients can be implemented using a set of links in a link category.

So, how would we go about and convert our static HTML into a fully dynamic site with a complete administration interface? Let's dig into some code.

# Getting access to WordPress from your code

The first step to a well-integrated site is to include the following code at the top of any page that needs to access WordPress functions. Naturally this does not need to be included in included/required files.

```php
define('WP_USE_THEMES', false);
require('./wp-blog-header.php');
```

This gives you access to a whole set of [WordPress functions](http://codex.wordpress.org/Function_Reference) that will aid us in integrating your site with WordPress. Unfortunately, the WordPress API is not very well structured, and naming conventions are a bit all over the place, but we'll make do.

# Getting content from WordPress

From the WordPress function list, there are a couple of terms you need to become accustomed to in order to start using the API. First of all, "The Loop".

Now, we will not actually be using the loop to display any of our pages for two reasons: "The Loop" is a magic thing that mysteriously figures out what posts/pages to display, and is associated with some magic methods such as get_the_author which magically contain data about the "current" post, whatever that is. Second, it provides very little flexibility for selecting only certain posts/pages.

I will not go into the details of "The Loop" here, I will just say that it is a while loop that most WordPress templates use to print blog posts, pages, etc. to abstract away the backend query. There are several methods in the WordPress API that depend on being used in The Loop, and these usually contain "the" in the function name. Avoid these!

Next, in WordPress, pages are posts. Special types of posts, but posts nonetheless. This means that if you fetch a page, the various fields available will be the exact same as those for post, and they will be named post_title, post_content, etc...

When printing the content of posts (that is, any field that has a rich text field as input), WordPress depends on you running the data through another magical function: [wpautop](http://codex.wordpress.org/Function_Reference/wpautop). This function automatically adds p tags where it thinks is appropriate to mimic the appearance in TinyMCE in the admin panel. Always put post_content through this function, otherwise your output is going to look very weird indeed.

Finally, the WordPress API usually returns objects or lists of objects. This is very convenient for most uses, but it also means that you have to take care in those cases where it doesn't. One such method that you will probably be using is wp_get_attachment_image_src; this function actually returns a numerically indexed array.

Most function that return objects contain all the fields outlined in the appropriate table in this database diagram: http://codex.wordpress.org/Database_Description. Note that almost all models will contain an ID field which comes in very handy. Most other columns are prefixed by the name of the table, and this prefix is also used in the object attributes.

# Getting posts

When getting blog posts, the main function to think about is get_posts. This function has [a plethora of configuration options](http://codex.wordpress.org/Template_Tags/get_posts), but usually, you will only need the numposts option, and maybe offset. In the case of the website I was developing, I wanted just the posts in a given category

```php
foreach ( get_posts ( 'numberposts=7&category=4' ) as $post ) {
    echo $post -> post_title;
}
```

This is a very simple example which only prints the title of each post, but you get the drift.

If you want a full version of a post given its ID, you would use the quite similar [get_post](http://codex.wordpress.org/Function_Reference/get_post) function. This function takes a post ID, and returns an object representing that post. This object tells you nothing about the author or any attached images, so these will have to be fetched separately as such:

```php
$post = get_post ( $_GET['p'] ); // This is probably quite insecure. Sanitize your input!
$author = get_userdata ( $post -> post_author ); // Here we should do some error checking on $post first
$images = get_children ( array(
    'post_type' => 'attachment',
    'post_parent' => $post -&gt; ID,
    'post_mime_type' => 'image'
) );
```

There is a bit of voodoo going on here, so let's take it step by step.

The first line should be pretty straightforward, we simply get the appropriate post object by its ID (which we take from the query string).

The next line is also quite simple, we fetch [the user data](http://codex.wordpress.org/Function_Reference/get_userdata) of the user with the ID matching that of the author of the post.

Now we get to the strange bit; [get_children](http://codex.wordpress.org/Function_Reference/get_children). You see, WordPress treats almost everything as posts. Even attachments, no matter the type, are considered posts, and are part of the page/post hierarchy. Thus, to get the attachments of a post or page, we are actually getting all the children of the given object of the type 'attachment'. I have also added a filter on 'post_mime_type' to ensure we only get images. Notice how WordPress sometimes uses strings as arguments, and other times uses arrays? Turns out you can usually get away with both approaches... Someone should really write a wrapper class to sort out that mess, but until then, we'll have to deal with it. The good part though is that the process for getting the images for a page is exactly the same, just replace get_post with get_page!

The most interesting part though is showing an image you've fetched. WordPress "conveniently" provides user-customizable thumbnails for all uploaded images. Unfortunately, these tend to be cropped in weird ways, and are very unpredictable and unlikely to look nice. When printing an image, you have a choice between several formats, amongst others 'thumbnail' (the default) and 'full'. The only one that gives you an uncropped image is 'full', but this will give you the image in its original resolution. True, the users can edit and scale the images in the admin panel, but how many end-users can you expect to do that? Unfortunately there is no way around that at the moment AFAIK, but one happy day...

Anyway, until then, you have a choice of two functions for printing your images: [wp_get_attachment_image](http://codex.wordpress.org/Function_Reference/wp_get_attachment_image) and [wp_get_attachment_image_src](http://codex.wordpress.org/Function_Reference/wp_get_attachment_image_src). They both take the same arguments, but the difference is that the first one prints a full 'img' HTML tag with the alt, title, width and height attributes already set, whereas the second one just returns the image url, the widht and the height as a numerically indexed array that you can decide what to do with. They both take the ID of the image as a first parameter, and the size you want as the second. Here, you can either give a predetermined size such as 'thumbnail', get the full image with 'full' or get a cropped thumbnail that fits inside a certain box by passing an array of two values, width and height as such: `array ( 64, 64 )`. If you want to get the image description and title yourself, those are stored in the object you used to get the ID for `wp_get_attachment_image_*`, i.e. in `$images[$i]`.

# Other attachments (mp3s for instance)

When it comes to getting other post attachments, this is actually quite trivial once you know how to fetch images. Instead of using `'post_mime_type' => 'image', you simply use another MIME type. On the site I am developing, I will use the MIME type for mp3 which is 'audio/mpeg' as far as WordPress can tell (you can see this in the WordPress admin panel -&gt; Media). I would therefore substitute  `'post_mime_type' => 'image'` with `'post_mime_type' => 'audio/mpeg'`. Simple as that!

To get the direct URL for a non-image attachment, you can use the [wp_get_attachment_url](http://codex.wordpress.org/Function_Reference/wp_get_attachment_url) function. As for getting the high quality version of a file, this is just a matter of selecting an attachment with the same title (i.e. the name of the file without the extension), but [a different MIME type](http://www.iana.org/assignments/media-types/).

# Dealing with pages/editable content boxes

Now, for the boxes on the about page which the administrators of the page should be allowed to edit. This is as easy as just creating two new pages in the WordPress admin and noting down the name you use. Back in your code, you can then use the following snippet to print the content of the box/page:

```php
$page = get_page_by_title ( 'About box left' );
echo wpautop ( $page -> post_content );
```

By now this should look familiar. We are simply fetching the pa[by its title](http://codex.wordpress.org/Function_Reference/get_page_by_title), and then passing the pages content through wpautop, and echoing the result.

# Lists of links with descriptions

Our final challenge for this site will be to fetch the list of clients. We've already determined that we are going to use the WordPress Links library because this provides exactly the fields we need, a title, a URL and a short description. However, if you start looking through the WordPress API for anything related to links, you will come up empty handed. The reason for this is that in their wisdom, WordPress decided to call links "bookmarks" in their API for the sake of clarity. The function we are looking for here is called [get_bookmarks](http://codex.wordpress.org/Function_Reference/get_bookmarks), and again we may specify lots of parameters. In our case, however, we are only concerned with one of them; category. Since we may want to add other links later that should not show up in the clients list, we create a link category from the WordPress admin and note down the category ID. In my setup it was 3, and so my code to get the links/bookmarks becomes:

```php
foreach ( get_bookmarks ( array ( 'category' => 3 ) ) as $link ) {
    echo '<a href="' . $link -> link_url . '">' . $link -> link_name . '</a>';
    echo '<blockquote><p>' . $link -> link_description . '</p></blockquote>';
}
```

Of course, this is a simplified version of the end result, but it should give you enough of an idea to get you on your way.

# Final thoughts

As you have now seen, this entire page can now be administered fully through WordPress with its quite good admin panel, and the user won't even think twice about WordPress really being a blogging tool. In fact, neither should you, because as you can see, it is more than flexible enough to be used for quite complex websites. Your users will be happy with a comfortable admin interface, and you won't have to touch a single piece of admin code!