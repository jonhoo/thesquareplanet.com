---
layout: post
title: RSS and XML
date: '2009-11-15 05:34:54'
---

One of the greatest merits of the web, and at the same time, one of its greatest vices, is its decentralization. Data is scattered all over the place; and although this makes for a diverse and ( to a large degree ) uncensored source of information and news, it also means that you have to go to several different sites whenever you wish to see what has happened since you were last online.

Luckily, this problem has a solution - syndication feeds. A syndication feed, which means the supply of material for reuse and integration with other material, is a machine-friendly list of newly updated or created items on a site containing metadata, and usually a piece of the body of the item. One site can have multiple such feeds, each catering for a different category or section.

The advantage of such feeds is that they are machine-readable. This means that you can have a piece of software either online or on your local computer which aggregates data from multiple such feeds, and joins them together into one large list of articles and updates for your viewing pleasure. No longer any need for visiting all those pages, instead, let a feed reader such as [Google Reader](http://www.google.com/reader) do the work for you, and then just browse through the list of updates from the pages you subscribe to.

So, how does this work? Well, there are several different feed formats ( unfortunately ), but the most common ones are Atom and RSS. Both rely on XML do describe the data, but with slightly different structure and each their advantages and disadvantages. Today I will be discussing RSS v2 ( there is a v1 as well, but it is currently being abandoned in favor of v2 ).

A RSS v2 looks like this: http://jonhoo.wordpress.com/feed/. Your browser has probably slapped on a pretty interface, but if you right-click the page and press "View Source", you will see the underlying XML. It will look something like this ( abbreviated for clarity ):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
        <title>Tech That!</title>
        <link>http://jonhoo.wordpress.com</link>
        <description>The rantings of a mad scientist</description>
        <language>en</language>
        <image>
                <url>http://www.gravatar.com/blavatar/6d568a76e1cf896c928d6ee52b5330f2?s=96</url>
                <title>Tech That!</title>
        <link>http://jonhoo.wordpress.com</link>
    </image>
    <item>
            <title>Portfolio live</title>
            <link>http://jonhoo.wordpress.com/2009/11/13/portfolio-live/</link>
            <pubDate>Thu, 12 Nov 2009 17:21:12 +0000</pubDate>
        <category><![CDATA[Me]]></category>
        <category><![CDATA[Tech]]></category>
        <category><![CDATA[portfolio]]></category>
        <category><![CDATA[Jon Gjengset]]></category>
        <category><![CDATA[thesquareplanet.com]]></category>
        <category><![CDATA[live]]></category>
        <guid isPermaLink="false">http://jonhoo.wordpress.com/?p=85</guid>
        <description><![CDATA[Finally, my long-awaited ( on my part at least ) portfolio is live!
                You can see it at http://thesquareplanet.com
                Design and coding entirely by me..]]>
            </description>
        </item>
</channel>
</rss>
```

This probably looks quite confusing, but let's take it bit by bit. Firstly, notice the root element of the XML: `<rss>`. This is compulsory for any RSS feed. Second, notice the version number also has to be included.

Next, we define our first channel. A channel is almost like a folder or a section-container. Everything put in a section is a part of the same category. We then proceed to describe the channel by giving it a title, a link and a description, as well as telling the reader what language the feed is using. All of these ( except language ) are compulsory.

Notice also the `<image>` preceding the metadata about the channel. This allows the reader to display a feed image to the end-user to easily identify your feed from a list of many. Sort of like a [favicon](http://en.wikipedia.org/wiki/Favicon) for your feed.

We then proceed to our first item. Again, we specify metadata about that item such as its title, its publication time, a list of categories and a link to the element. Wordpress also specified as GUID - a Globally Unique IDentifier. This is a string that should uniquely identify this one item in any collection of URLs.

The last tag in `<item>` is the `<description>` tag. Either this or the `<title>` tag HAS to be present in any valid RSS v2 feed. The `<description>` tag should contain an excerpt of the item.

And that's it.. Nothing more is needed to make a full RSS feed, with all its glory and genius. Happy feeding!

For a complete overview of the RSS standard, have a look at http://cyber.law.harvard.edu/rss/rss.html.