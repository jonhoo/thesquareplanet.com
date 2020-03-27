---
layout: post
title: "Livestream tips"
date: '2020-03-27 12:18:59'
---

Now that an increasing number of people are staying at home, more people
are asking me for advice on how to get started with live streaming. I
think this is _great_ (yay for sharing knowledge!), so I want to share
some of that advice here to make it more broadly accessible. This advice
is primarily targeted at people live-streaming technical content, but
may also be applicable beyond that.

If this was useful to you, or you have a question that isn't answered
here, please [let me know](https://twitter.com/jonhoo)!

# Software

I use [OBS Studio](https://obsproject.com/), and am very happy with it.
It supports all sorts of input sources, works on most platforms, and
supports both recording and streaming out of the box. It even lets you
inject websites into your video to include dashboards, chat, etc. should
you want it.

I stream concurrently to both YouTube and Twitch using
[restream.io](https://restream.io/). The service is free, and also takes
care of synchronizing your chat between the two platforms. I have no
complaints about it, and it's also easy to set up with OBS. I
multistream to those two platforms because I find that people have
strong preferences for what platform they want to watch on, and who am I
to say no. On average, about a quarter of my live viewers are on Twitch,
and the rest on YouTube. Twitch has lower latency, better quality, and
fewer connection problems, but YouTube presents a wider audience.

For drawing things, I use [MyPaint], and it seems to do the job nicely.

  [MyPaint]: http://mypaint.org/

# Hardware

**Get a decent microphone**. If there is _one_ thing you take away from
this, it's that. A proper, standalone microphone is _so_ much better,
and not even all that expensive. I started out with the [Samson Q2U],
and was very happy with it. You can hear what it sounds like in [one of
my first videos]. I've since upgraded to the [RØDE Podcaster] (which
sounds [like this]), and I doubt I'll need anything more fancy that that
ever. I'll add that the step up from the Samson to the RØDE _is_
noticeable (just see the comments).

I recommend also getting a mic boom (an arm that holds your microphone). 
It lets you position the mic closer to your mouth, which makes your
voice clearer and reduces the noise from your keyboard and desk. Compare
this video [without a boom] to this one [with a boom]. For the Samson
Q2U microphone, I used this [InnoGear arm], and for the RØDE I got their
[PSA1 arm]. Both work great.

If you're going to be doing live programming with a lot of typing, I'd
also recommend investing in a shock mount. They're pretty cheap, and
they reduce amount of vibration from your key presses that gets picked
up by the microphone (which users [do notice]), as well as [thuds][thud]
if you accidentally hit your mic. To hear the effect, compare the video
with the [thud] to one [with a shock mount]. I only ever got one for my
new mic, not the old one, and there I went with the [RØDE PSM1].

I've also found that it's really useful to have a drawing tablet of some
kind for simple whiteboarding. Pretty much any tablet will do. I'm using
the relatively simple [Huion H640P] and it does the job.

It's not _necessary_, but I also suggest getting a small second monitor
where you can have non-public things open during the stream. For me, the
primary use for this is chat. That way, you can devote your full primary
screen real-estate to the stream without having to cramp things due to
the space taken up by the chat window.

Having OBS run video encoding in the background _may_ put a strain on
your computer, so you'll want to make sure you have the hardware to
drive full 1080p encoding while also compiling code (or doing whatever
else it is you are streaming). I did my first few streams on my laptop,
and that worked okay, but the stream quality did suffer as a result. I
now do my live coding on a desktop with more cores and a (not very
fancy) GPU, and that works way better. A short test stream is great for
figuring this stuff out! You may want to consider restricting the number
of cores you allow your compiler to use using something like [`curb`],
[`hwloc-bind`], or [`numactl`].

Don't worry too much about your internet connection. Fast is great, but
my streams seem to be doing okay with a meager 5Mbps upload speed.

  [Samson Q2U]: http://www.samsontech.com/samson/products/microphones/usb-microphones/q2u/
  [one of my first videos]: https://www.youtube.com/watch?v=Zdudg5TV9i4&list=PLqbS7AVVErFifv2Ek-bCRhrVyi_dQeqcY
  [RØDE Podcaster]: https://www.rode.com/microphones/podcaster
  [like this]: https://www.youtube.com/watch?v=DkMwYxfSYNQ
  [without a boom]: https://www.youtube.com/watch?v=jTpK-bNZiA4
  [with a boom]: https://www.youtube.com/watch?v=Qy1tQesXc7k
  [InnoGear arm]: https://www.innogear.com/products/microphone-stand-mic-windscreen-and-mic-pop-filter-set
  [PSA1 arm]: https://www.rode.com/accessories/psa1
  [do notice]: https://www.reddit.com/r/rust/comments/d4bxb8/the_why_what_and_how_of_pinning_in_rust_video/f0jy1mk/
  [thud]: https://www.youtube.com/watch?v=DkMwYxfSYNQ&t=8769s
  [with a shock mount]: https://www.youtube.com/watch?v=bJmlI4Ug-p0
  [RØDE PSM1]: https://www.rode.com/accessories/psm1
  [Huion H640P]: https://www.huion.com/pen_tablet/H640P.html
  [`curb`]: https://github.com/jonhoo/curb
  [`hwloc-bind`]: https://linux.die.net/man/1/hwloc-bind
  [`numactl`]: https://linux.die.net/man/8/numactl

# Content and Structure

Probably one of the #1 questions I get is "what should I stream about"?
This one is tough, because there isn't one good answer. But let me try
to give some pointers. Think about what you enjoy working on or talking
about, and what you think you'd be able to coach people along through.
And then stream that. Perhaps obviously, your streams will be best when
you are excited about what you're streaming! Don't worry too much about
what the viewers want to see — trying to guess what other people are
interested in is a losing game. In my case, I just picked one from my
pile of "stuff I wish existed but never have the time to do myself", and
then did that.

For programming streams in particular, the one bit of more concrete
advice I can give is that it's good to not dive in the very deep end at
the start of a stream. Instead warm people up by explaining the problem
and letting them be a part of researching the solution. If you already
have a plan for what you're going to implement and how, it's unlikely
the audience is going to be able to follow along. In my case, my first
stream was basically "I need this thing, and would need to build it from
scratch, so let's just do that together". It included a lot of figuring
out how to do what I wanted to do on-stream, and I think that's a good
thing.

The key piece for any stream is to make sure you are talking, and
preferably explaining, as you go. Speak your thoughts aloud. If you sit
there quietly writing code, you'll lose most viewers. This is perhaps
one of the most important parts of an interesting stream: don't be
silent.

# Announcements

People like to plan, and then forget things. Write a post ~1 week in
advance, and then post a brief reminder 24 hours before the stream
begins.

Make your announcement self-contained. If you want people to share your
announcement, make it as easy as possible for them to do so. Include a
brief description of what you'll be streaming, the date/time, and the
location. If you have space, you should also include a brief bit about
the intended audience and planned length.

Remember people in other timezones. I tend to announce all streams in
UTC time, and then link the exact date/time on
[everytimezone.com](https://everytimezone.com/) so that people can
easily see what that time translates into where they are. The 24h
reminder also works well for that, since people can look at when the
post was made their time, and then just add 24h.

Announce the recording when it's ready. After your stream has concluded
and the recording of it is available online, write another brief post
that links to the original announcement, gives a brief recap of how it
went, and then links to the video.

# The Stream Itself

Do a test stream! Things will inevitably go wrong the first time, so
have it be something that doesn't matter. Invite a few people to be your
"viewers" so they can help you test on the receiving end.

Start your stream ~10m early with a static screen (you can set this up
in OBS) showing some text like "Starts at 5pm UTC". This lets viewers
who show up early know that they're in the right place, and allows them
to start chatting before the session itself begins. I usually also jump
on a few minutes early with audio-only both to chat informally and to
test audio levels and chat.

Use a separate browser window, and maybe even a separate browser
profile, for your streams. Your old tabs and history auto-complete can
be both revealing and distracting.

Do not type passwords on-screen during your stream. Move the password
input off-screen before typing. If you're paranoid (like me), set a
hotkey for muting your mic as well when you're typing them in.

Don't show chat on screen. It takes up screen real-estate, and means
that people can't opt out. Those who _really_ want it after the fact can
watch the saved live-stream (see below). Also saves you from when people
type weird things you want to ignore in chat.

Increase your font size. Then increase it some more. People will be
watching your streams on small tablets, or even their phone, and at
1920x1080, your normal font size is going to be impossible to read.
Another good reason to do a test stream and get feedback!

Avoid switching rapidly between dark and bright windows. If someone is
watching in a relatively dark room, this can be extremely jarring. Open
the windows side-by-side, or at least warn them that this will happen
before you do it.

Do a quick audit of your OBS stream layout. It's no good if your webcam
video overlay hides an important window on your screen for example. Try
out the main few views you will have on screen during the stream, and
see that the OBS output view looks reasonable.

Record your stream locally when you start, and upload that to YouTube
after you're done. The auto-saved version is affected by poor connection
stability and includes your "stream starting in 10m screen", which is
just annoying. Make the uploaded version public, and the saved
live-stream version unlisted, then link to the live-stream version from
the recorded version for those who want to see chat.

Happy streaming!

Jon
