---
layout: post
title: "My First Podcast: A Tale of a Broken Ecosystem"
date: '2019-07-10 07:49:37'
shared:
  Hacker News: https://news.ycombinator.com/item?id=20402120
  Twitter: https://twitter.com/Jonhoo/status/1148958976228257793
---

I've been playing around with the idea for a new podcast along with a
couple of other Rustaceans recently, and a little while back we decided
to go ahead and record an episode on the newly release Rust 1.36.0 (stay
tuned!). Yesterday, I spent some time trying to get all the "stuff" set
up to actually release the podcast, and it resulted in perhaps the most
frustrating few tech-related hours I've had in a few years.

I decided I didn't want anything fancy; I'd just upload the recorded
episode to [Backblaze B2](https://www.backblaze.com/cloud-storage),
where I already have an account for backup purposes, and then use
[GitHub Pages](https://pages.github.com/) for a super-barebones website
and an RSS feed for the podcast episodes. Seems simple enough, right? I
just needed to figure out the feed stuff, and then I'd be good to go.

So, as any lazy programmer does, I started by searching for "jekyll
podcast rss", since GitHub pages is [basically
Jekyll](https://help.github.com/en/articles/about-github-pages-and-jekyll).
And lo and behold, "[Podcasting with Jekyll in 4
Steps](https://dyscribe.com/en/podcasting/podcasting-with-jekyll-in-4-steps.html)"
pops up. Great! I'll be done in no time. Seems easy enough. Steps 1 and
2 I've already completed. Copy-paste the RSS template, and it seems to
generate correctly, great!

Now just to double check, let's run it through a validator. "itunes
podcast rss validator" brings up [Cast Feed
Validator](http://castfeedvalidator.com/),
[podbase](https://podba.se/validate/), and [FEED
validator](http://www.feedvalidator.org/). I guess let's try all three.
They all complain about slightly different things, like the
`<atom::link>` tag not pointing to the right URL, so I do some tweaking
to make things work on GitHub Pages. Oh, yeah, and apparently iTunes
only accepts [certain HTTPS
certificates](https://support.castos.com/article/72-itunes-can-t-read-your-feed),
and the one used by GitHub Pages isn't one of them. I guess I'll have to
proxy through CloudFlare or something.

This process does cause me to read through the XML more carefully
though, and I see a number of other things that seem odd. First, there
are several calls to `xml_escape`, which seems weird given the existence
of [CDATA](https://en.wikipedia.org/wiki/CDATA). Second,
`<description>`, `<itunes:subtitle>`, and `<itunes:summary>` seem very
overlapping -- how do they differ? It's time to look for the spec!

iTunes seems to be the primary standard-setter for podcast RSS feeds, so
I quickly end up at Apple's [Podcast feed
sample](https://help.apple.com/itc/podcasts_connect/#/itcbaf351599).
Except this also has a number of tags my feed does not, such as
`<itunes:type>` and `<itunes:title>` (how does it differ from
`<title>`?). I also see that they are nesting something called
`<content:encoded>` inside of `<description>`, and also using CDATA.
Their value in `<itunes:duration>` is in seconds, not as HH:MM:SS. I try
to match my XML to theirs --- it now fails validation. Okay... Is there
a full specification somewhere?

I find Apple's [Podcast best
practices](https://help.apple.com/itc/podcasts_connect/#/itc2b3780e76),
which goes into some more details about the difference between different
tags (like summary and description). They say that `<content::encoded>`
should be _separate_ from `<description>`, in direct contradiction of
the feed example. They also recommend `<itunes:type>`, except that tag
is rejected by the validator as not part of the schema.

I find Apple's [Podcaster's guide to
RSS](https://help.apple.com/itc/podcasts_connect/#/itcb54353390). This
has an official-looking table with "required tags" and "recommended
tags". Finally! Except here, for `<description>`, the example shows
`<content:encoded>`? The "best practices" document also said that
`<content:encoded>` could be used at "episode-level only", whereas this
document seems to say that _all_ description elements should have it?
At the bottom, it says "only use markup or HTML contained within
`<content:encoded>` tags inside of `<description>` tags", reiterating
that one should be _inside_ the other, even though this seems contrary
to the [RSS
spec](http://www.rssboard.org/rss-profile#namespace-elements-content-encoded)
(see also
[StackOverflow](https://stackoverflow.com/questions/7220670/difference-between-description-and-contentencoded-tags-in-rss2)).
The spec also says that if `<content:encoded>` is present, `<description>`
should be used as a summary (so what is `<itunes:summary>` for?).

This document also specifies that `<itunes:title>` should be used for
episode titles, not `<title>`, whereas the same is not true for the
channel title. At least it clarifies that `<itunes:duration>` can take
"different duration formats", so that (maybe) explains it being given in
both seconds and HH:MM:SS format. Oh, and `<itunes:keywords>` is also
apparently not a thing. And when it says that you can use `false` or
`true` for things like `<itunes:explicit>`, that's a lie -- you must use
`no` or `yes`.

Okay, so that is a hot mess. Let's see what schema Google recommends for
its podcast feeds. Some initial Googling leads us to [this
page](https://www.google.com/schemas/play-podcasts/1.0/), which has a
link to the XSD schema file and a [Google Support
answer](https://support.google.com/googleplay/podcasts/answer/6260341).
The latter _does_ give an outline of the required tags, but it seems to
mostly be "do what iTunes requires and we'll figure it out". They
provide their own `googleplay` namespace if you need to, say, [use
a different e-mail address on
Google](https://twitter.com/Jonhoo/status/1138189951437135872).
Unfortunately, their "Sample podcast RSS feed" [doesn't
validate](http://www.feedvalidator.org/check.cgi?url=https%3A%2F%2Fgist.githubusercontent.com%2Fjonhoo%2F20fbc04ce70c8c4d90c8310cb8327e34%2Fraw%2Fb0f35300937c1ca8807144316431e0b58f4a5d02%2Fgoogleplay-podcast-sample-feed.xml),
because:

> Use of unknown namespace: http://www.google.com/schemas/play-podcasts/1.0

Great, so the `googleplay` namespace doesn't work, so you can't use a
different e-mail address for iTunes and Google Play. Fantastic.

Okay, whatever, let's at least just see whether iTunes will accept what
I [now
have](https://gist.github.com/jonhoo/b84935123965c6508e143cc271b48c59).
I'm just going to sign up for an Apple ID real quick. Just have to fill
out [this little form](https://appleid.apple.com/account#!&page=create)
(which requires JavaScript, because of course it does) and then verify
my e-mail. Easy enough.

> Your account cannot be created at this time.

Err, what? Okay, different e-mail address?

> Your account cannot be created at this time.

Err, okay, different browser?

> Your account cannot be created at this time.

Different browser, e-mail address, and over VPN?

> Your account cannot be created at this time.

I guess it's time to contact Apple support. My only option is to either
have them call me or schedule a call for later. No idea why online
support isn't a thing, but okay. I put in my phone number and the
cryptic error message and wait. Two minutes later, I get a text from
[Google Fi](https://fi.google.com/) that I have a missed call.
Apparently Apple Support tried to call me and it went to voicemail. Huh,
weird. I was by my phone the whole time and it never rang. I get an
e-mail saying they failed to reach me and will try again. I get another
missed call from voicemail. Apple gives up.

After digging through my calls list, I notice that the missed calls show
the incoming calls from Apple with the "Blocked spam caller" icon.
Uh-oh. I guess Google Fi marks Apple Support as spam? Great. I unmark as
spam and file another support ticket. The call goes through immediately.

Okay, so I'm speaking to Porschia. Seems friendly enough. I tell them my
issue again and my e-mail address. They disappear for a while,
occasionally checking back that it'll just be a bit longer. After about
10 minutes of mostly silence, they tell me to try again. It works! I ask
why. "Your e-mail had to be whitelisted". What?! Apparently Apple
doesn't like people with e-mail addresses under custom domains signing
up for an Apple ID? How bizarre.

Well, I have an Apple ID account now, so onwards! The Interwebs tell me
that I should now go to [Podcasts
Connect](https://podcastsconnect.apple.com/), so I do.

> Podcasts Connect requires an iTunes Store account.

Err... And that's _different_ from an Apple ID? Apparently a magic
"[blessing](https://support.apple.com/en-us/HT201762)" happens to your
Apple account the first time you log in through an Apple product (either
a device or iTunes). And that blessing is needed to publish a podcast.
I guess that's next. But... I'm on Linux, and I own no Apple devices.
There is quite literally no way for me to log into an Apple product.
Unless...

A while back, Microsoft released [Windows virtual machine
images](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/)
to allow you to test stuff in older versions of Internet Explorer.
They're free to download, but expire after 90 days. That's fine. I just
need to _log in to iTunes_. So, I download a Windows VM, install iTunes
on there, log in with my new Apple ID, give my address, and click
continue expecting that there's some additional process I have to go
through involving a credit card and whatnot to get my account blessed.

> You have been logged in to iTunes.

So, let me get this straight. I had to download a 6GB Windows VM + 200MB
of iTunes just so I could fill in my address? There really wasn't any
way I could have done this through the web Apple? At least I'm not the
only one who has commented on [this being
stupid](http://rickluna.com/wp/2016/08/submitting-a-podcast-to-itunes/)
in the past.

Anyway, with my special iTunes Store account in hand, I now navigate
back to Podcasts Connect, and am met with a mostly blank page with a
single text input field named "RSS Feed URL". I give it what it wants,
and it spins for a while. Then

> Failed Validation

No further explanation. It just.. Failed. Back to the other validators I
guess. The unrecognized Google Play schema definition was the only
reported error, so I removed that. An what do you know, that was it.
iTunes validated my XML! Now let's just double-check the details it has
extracted. Huh, that's weird. The episode listing shows a blank string
under "Description" for the included episode. After some digging, it
turns out that the podcast episode "Description" in this list is, wait
for it... `<itunes:subtitle>`. Because it'd be silly if it was _any of
the three other tags that are meant to be descriptions_.

But hey, at least now I _think_ I'm about ready to publish this thing.
Cue record scratch...
