---
layout: post
title: RSS feed for AlertBox
date: '2010-06-17 05:18:15'
---

For those of you concerned with web usability, there are few better sources than Jakob Nielsen's [AlertBox](http://www.useit.com/alertbox/).

Although his site is quite infrequently updated, it contains very informative posts. Unfortunately and ironically, the site does not have a RSS feed.

After an especially boring afternoon, I decided to see if I couldn't do something about that, so with the use of this [PHP Feed Generator](http://phpclasses.realsauce.com.au/package/4427-PHP-Generate-feeds-in-RSS-1-0-2-0-an-Atom-formats.html) class and some HTML parsing, I came up with the following script to generate an RSS feed from the AlertBox website:

Just download the FeedGenerator FeedWriter class from the given link, put the following code and FeedWriter.php in the same directory, upload it to a webserver with PHP support, and voilla, you have an AlertBox RSS feed.

Enjoy!

```php
<?php

date_default_timezone_set("UTC");
class FetchAlertbox {
    private $contents = array();
    private function fetch() {
        $page = file_get_contents("http://www.useit.com/alertbox/index.html");
        $startList = stripos ( $page, '<ul>' );
        $page = substr ( $page, $startList, stripos ( $page, '</ul>;', $startList ) - $startList + strlen ( '</ul>' ) );
        $page = str_ireplace ( '<p>', '', $page );
        $page = preg_replace ( "/<li>(.*)/i", '<li>$1</li>', $page );
        $page = preg_replace ( "@</?strong>@i", "", $page );
        $p = @DOMDocument::loadHTML($page);

        foreach ( $p->getElementsByTagName("li") as $article ) {
            $url = '';
            foreach ( $article->getElementsByTagName("a") as $link ) {
                if ( preg_match ( "@\w+.html@i", $link->getAttribute('href') ) ) {
                    $url = 'http://www.useit.com/alertbox/' . $link->getAttribute('href');
                    break;
                }
            }

            if ( $url === '' ) {
                continue;
            }

            $contents = str_replace ( "\n", " ", $article->textContent );
            $contents = preg_replace ( "/\s{2,}/", " ", $contents );
            $date = 0;
            $possibleStartDate = strrpos ( $contents, '(' );
            if ( $possibleStartDate !== false ) {
                $timestring = substr ( $contents, $possibleStartDate + 1, strpos ( $contents, ')', $possibleStartDate ) - $possibleStartDate - 1 );
                $parsedDate = strtotime ( $timestring );
                if ( $parsedDate !== false ) {
                    $date = $parsedDate;
                    $contents = str_replace ( "($timestring)", "", $contents );
                }
            }

            $this->contents[] = array ( 'url' => $url, 'title' => trim ( $contents ), 'date' => $date );
        }

        return $this->contents;
    }

    public function fetchWithSummaries($type = "RSS2", $limit = 10, $start = 0) {
        if ( empty ( $this->contents ) ) { $this->fetch(); }
        include ( "FeedWriter.php" );

        $feedType = RSS2;
        $feedDate = DATE_RSS;
        switch ( $type ) {
            case 'RSS1':
                $feedType = RSS1;
                break;
            case 'ATOM':
                $feedType = ATOM;
                $feedDate = DATE_ATOM;
                break;
        }

        $feed = new FeedWriter($feedType);
        $feed->setTitle("Alertbox");
        $feed->setLink("http://www.useit.com/alertbox/");
        $feed->setDescription("Current Issues in Web Usability - Bi-weekly column by Dr. Jakob Nielsen, principal, Nielsen Norman Group");

        if ( $type === 'ATOM' ) {
            $feed->setChannelElement('updated', date($feedDate, $this->contents[0]["date"]));
        } else {
            $feed->setChannelElement('pubDate', date($feedDate, $this->contents[0]["date"]));
        }

        $feed->setChannelElement('language', 'en-us');
        $feed->setChannelElement('author', array('name' => 'Dr. Jakob Nielsen'));

        if ( $type === "RSS1" ) {
            $feed->setChannelAboute("http://www.useit.com/alertbox/");
        }

        for ( $i = $start; $i < $start + $limit && $i < count ( $this->contents ); $i++ ) {
            $p = @DOMDocument::loadHTML ( file_get_contents ( $this->contents[$i]["url"] ) );
            $blockquotes = $p->getElementsByTagName("blockquote");
            if ( $blockquotes->length &gt; 0 ) {
                $this->contents[$i]["summary"] = trim ( str_replace ( "Summary:", "", $blockquotes->item(0)->textContent ) );
            } else {
                $contents = $p->saveHTML();
                $endHeadline = stripos ( $contents, "</h1>" );
                $this->contents[$i]["summary"] = trim ( strip_tags ( substr ( $contents, $endHeadline + strlen ( "</h1>" ), stripos ( $contents, "<p>" ) - ( $endHeadline + strlen ( "</h1>") ) ) ) ) );
            }

            $item = $feed->createNewItem();
            $item->setTitle($this->contents[$i]["title"]);
            $item->setLink($this->contents[$i]["url"]);
            $item->setDate($this->contents[$i]["date"]);
            $item->setDescription($this->contents[$i]["summary"]);
            $feed->addItem($item);
        }

        $feed->genarateFeed();
    }
}

$s = new FetchAlertbox();
$s->fetchWithSummaries(isset($_GET['type']) ? strtoupper ( $_GET['type'] ) : 'RSS2', isset($_GET['limit']) && ctype_digit($_GET['limit']) ? $_GET['limit'] : 10);
```