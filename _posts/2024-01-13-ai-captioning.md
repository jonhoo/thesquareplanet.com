---
layout: post
title: "Captioning all my YouTube videos with AI"
date: '2024-01-13T09:13:14Z'
shared:
  Twitter: https://twitter.com/jonhoo/status/1746280573998399650
  Mastodon: https://fosstodon.org/@jonhoo/111750723040665348
  LinkedIn: https://www.linkedin.com/posts/jonhoo_captioning-all-my-youtube-videos-with-ai-activity-7152046290095239168-I-Tz
  Discord: https://discord.com/channels/1130889237236027454/1130889954579456110/1195839348185247844
  Hacker News: https://news.ycombinator.com/item?id=38985150
  Lobste.rs: https://lobste.rs/s/ddssxd/captioning_all_my_youtube_videos_with_ai
---

Every month or two, I get an email asking whether I could enable
captions on [my YouTube videos][yt]. I also get asked [on Twitter], [on
Reddit], and even [on the orange site][hn]. Unfortunately, every time
I'm forced to give the same answer: I already have auto-captioning
enabled on my videos, but for some reason YouTube sometimes simply _does
not generate_ captions. The most common case appears to be because the
video is too long (somewhere around 2h), but I've seen it happen for
shorter videos as well.

Each time I give that reply, it makes me sad. It means that someone who
expressed an interest in learning from my videos was (at least in part)
prevented from doing so, and that sucks. So, with the last email I got,
I decided to finally do something about it.

Ages ago, a co-worker of mine suggested I might be able to use AI to
generate captions for my videos. There are a bunch of such services
around these days, but the one he linked me to was [Gladia]. So when I
finally decided to generate captions for all my videos, that's where I
started. [The API] is pretty straightforward: you send them a video or
audio file (or even a YouTube URL), and they return a list of captions,
each with an associated start time and end time[^long-captions]. That
list can then pretty easily be turned into SRT or VTT caption files
(Gladia also supports [producing them directly][srtvtt], though I didn't
use that feature). Seemed easy enough!

Unfortunately, it turns out that Gladia (and many other similar
platforms) have a [max limit] on the length of the file they are able to
caption. For Gladia, it's currently 135 minutes (though [they recommend]
you split your audio files into ~60 minutes chunks). Now, if you've
watched my videos, you know that most of them are longer than that, so
some smartness was needed (more on that in a second).

I also faced another issue: my video backlog is somewhere around 250
hours of video. At the time of writing, Gladia [charges €0.000193 per
second][price] of audio (which seems to be roughly where the industry
has landed), which works out to €174. That's not nothing, especially
with a bit of trial and error needed to get the aforementioned splitting
right. Luckily, when I reached out to them pointing out that I wanted to
caption a bunch of programming teaching resources, and was willing to
share my experience and code afterwards, they graciously agreed to cover
the cost of the bulk encoding. Yay!

With that out of the way, let's get to the how. You can also just look
at [the code] directly if you want!

# Generating captions for long videos

My videos vary a fair bit in length. The shortest are 60-90m (so within
the Gladia length limit), while [the longest one is 7h20m][long]. Some
may call that too long, but that's outside the scope of this. This
raises the question: how do you generate captions for a 7 hour long
video in bursts of approximately 60 minutes? The naive approach is to
just split the video in 60 minute chunks, caption each one
independently, and then join them together, but this presents a few
problems:

1. You may cut the video mid-sentence, leading to a broken caption.
1. You may cut the video during a short silence where the next caption
   should follow on from a sentence just before the silence. Splitting
   here would lead to odd-looking captions where the next caption
   appears to start a new sentence.
1. Depending on how you cut, you may end up with slightly-offset
   captions in later segments if the cutting isn't using precise time
   codes.
1. You may end up with "weird ends" where the last segment is only a few
   seconds long, possibly without any captions. This isn't inherently a
   problem, though it does mean that progress can appear kind of random.

Instead, you have to be slightly smarter about how you cut. Here's what
I landed on.

First, get the audio file for the video locally somehow. If it's a
YouTube video, you can use a tool like [`yt-dlp`] or [`yt-download`] to grab it:

```console
$ yt-dlp -x -f 'bestaudio' "https://www.youtube.com/watch?v=kCj4YBZ0Og8"
```

In my case, I have the files for all my videos locally, so I just used
those.

Next, take the length of the video and divide it by 60 minutes. Round
that number up to the nearest integer value. Then divide the length of
the video by that value (call that value `seg`). That's how long we'll
make each segment.

Then, extract the first segment (of length `seg`) with[^server-split]

```console
$ ffmpeg -i "$audiofile" -vn -c:a libopus -b:a 192k -f ogg -t "$seg"
```

> It's tempting to use `-acodec copy` here, but don't --- it leads to
> [inaccurate cutting]. We need to mux to get exactly-accurate cuts of
> the audio. So, we export to Opus audio in an Ogg container --- it is
> modern, compact, and has good encoders. FLAC would be nice, but hits
> the 500MB file size limit too often. I decided against AAC since some
> AAC encoders are _really_ bad.

Later segments can be extracted with:

```console
$ ffmpeg -ss "$start" -i "$audiofile" -vn -c:a libopus -b:a 192k -f ogg -t "$seg"
```

Note that the _last_ segment has to be extracted without the `-t` flag
to make up for any rounding errors!

> Sometimes, the audio stream in a video has a delay relative to the
> video stream. This might be to correct audio/video sync, or to make an
> intro sound line up with the visuals. This makes things weird because
> the caption timestamps are relative to the *video*. You can check
> whether this is the case for a given video file with this command:
>
> ```console
> $ ffprobe -i "$videofile -show_entries stream=start_time \
>     -select_streams a -hide_banner -of default=noprint_wrappers=1:nokey=1
> ```
> 
> If this prints anything but 0, you'll have to adjust the `ffmpeg`
> invocation for the _first_ segment to include `-af
> adelay=$offset_in_ms`.
>
> Note you have to have both the audio _and_ video to run this command,
> so remove `-x -f 'bestaudio'` if you're grabbing a YouTube video that
> might have such a delay.

But, how do you set `$start` for each segment?

First, ship the extracted audio segment to the Gladia API. Then, in the
[captions you get back][caps][^big-json], walk _backwards_ from the last caption,
and look for the largest inter-caption gap in, say, the last 30 seconds
of the segment. The intuition here is that the longest gap is the one
least likely to be in the middle of a sentence. You can also improve
this heuristic to look at what the caption immediately before the gap
ends with. For example, if it ends with "," or "…", maybe skip that gap
as the next caption is probably related and shouldn't be split apart.

Once you've found that gap, set `$start` to be the time half-way through
that gap. Discard all captions that follow `$start` from the current
segment, then repeat the whole process for the next segment. Keep in
mind that for all captions you get back from the API need to have
`$start` added to their time codes!

Once you have all the captions from all the segments, all that remains
is to write them out into the SVT format (one of the caption file
formats that YouTube supports). The format is:

```

$number
$caption.time_begin --> $caption.time_end
$caption.transcription
```

where `$number` starts at 1 for the first caption and increases by one
for each subsequent caption, and the timestamps are printed like this:

```rust
fn seconds_to_timestamp(fracs: f64) -> String {
    let mut is = fracs as i64;
    assert!(is >= 0);
    let h = is / 3600;
    is -= h * 3600;
    let m = is / 60;
    is -= m * 60;
    let s = is;
    let frac = fracs.fract();
    let frac = format!("{:.3}", frac);
    let frac = if let Some(frac) = frac.strip_prefix("0.") {
        format!(",{frac}")
    } else if frac == "1.000" {
        // 0.9995 would be truncated to 1.000 at {:.3}
        String::from(",999")
    } else if frac == "0" {
        // integral number of seconds
        String::from(",000")
    } else {
        unreachable!("bad fractional second: {} -> {frac}", fracs.fract())
    };
    format!("{h:02}:{m:02}:{s:02}{frac}")
}
```

Note that the SVT format is pretty strict. You _must_ have an empty line
between each caption, you must give them consecutive sequence numbers
starting at 1, you must use `-->`, and you must format the sequence
numbers with exactly three fractional digits.

I've coded up this whole process in this project on GitHub:
<https://github.com/jonhoo/gladia-captions>. I've also filed [a feature
request][split-feature] for Gladia to support something like this
natively.

# Mapping video files back to YouTube

If all you wanted to do was play someone else's YouTube file with
captions, then you're basically done. Just pass the SRT file to your
video player along with the YouTube URL (if it supports it) or the video
file you downloaded, and you're good to go.

If, like me, you want to update the YouTube video's captions, you next
need to figure out which YouTube video each caption belongs to. If you
downloaded the audio from YouTube originally, or have a neatly organized
video backup archive, then this is trivial. In my case, my local video
archive only has video category and the recording time of the video, so
there's no real connection to the originating YouTube video. So, I had
to also find a way to map the videos back to their respective YouTube
upload.

To do this, I wrote a program that first queries the YouTube API for all
my videos and extracts their id, title, publication date, and duration.
Then, it walks all the video files in a given directory and determines
their timestamp (from the file name) and duration (using [`symphonia`]).
Finally, for each local file, it checks if any of the YouTube videos
have a duration that differs in at most single-digit seconds, and has a
publication date that differs by at most a day. If any such video is
found, it associates the two, and outputs the YouTube id and title in
the name of the caption file for that local file.

# Uploading the captions

Armed with the caption files _and_ the mapping back to YouTube videos, I
really wanted to automate the process of uploading the captions as well.
It's not too important for captioning new videos, but when doing the
backlog of almost 80 videos, that's a lot of clicking through the
YouTube studio API. Now, there _is_ [an API for uploading
captions][cap-api], but unfortunately there are two complications:

1. It accesses private data, which requires [OAuth 2.0
   authentication][oa2]. A simple API key won't do it. It's totally
   possible to implement OAuth 2.0 authentication from a command-line
   tool, it's [just annoying][oa2-impl].
2. YouTube's upload API uses a particular kind of request encoding
   ([chunked transfer encoding][chunks]) that [isn't supported][reqwest]
   by the Rust HTTP library I'm using at the moment.

So I instead opted to do this part in Python (for now) based on the code
in the "Try it" box on the [caption API page][cap-api] (and the
[instructions for running it][run-example]). This required getting a set
of OAuth credentials from Google Cloud Console (not too bad since I
already had an "application" there for my API key), adding myself as a
"Test user" under "OAuth consent screen", and tweaking the code a bit.
The end result is [this Python script][py], which you should easily be
able to fit a slightly-different use-case.

> It's worth noting that the YouTube API has a pretty strict free quota,
> and that uploading captions consumes a fair bit of that quota (450 out
> of 10k daily limit). This means that in practice you can only upload
> about 20 captions a day through the API before YouTube will cut you
> off for the day. And getting that limit bumped [is annoying][yt-bump].

# End result

All [my videos], including the super long ones, will soon have English
captions (once the YouTube API allows), and I no longer need to
apologize for YouTube auto-captioning's shortcomings 🎉

[yt]: https://www.youtube.com/@jonhoo
[on Twitter]: https://twitter.com/junderwood4649/status/1603990798965833728
[on Reddit]: https://www.reddit.com/r/rust/comments/xzaljf/comment/irlwgjt/?context=3
[hn]: https://news.ycombinator.com/item?id=37946887
[Gladia]: https://www.gladia.io?utm_source=Twitter&utm_medium=Community&utm_campaign=jonhoo&utm_content=landing
[The API]: https://docs.gladia.io/reference/pre-recorded
[srtvtt]: https://docs.gladia.io/reference/export-srt-or-vtt-caption-files
[max limit]: https://docs.gladia.io/reference/limitations-and-best-practices
[they recommend]: https://docs.gladia.io/reference/limitations-and-best-practices#splitting-oversize-audio-files
[price]: https://www.gladia.io/pricing
[the code]: https://github.com/jonhoo/gladia-captions
[long]: https://youtu.be/zGS-HqcAvA4
[`yt-dlp`]: https://github.com/yt-dlp/yt-dlp
[`yt-download`]: https://ytdl-org.github.io/youtube-dl/
[inaccurate cutting]: https://superuser.com/questions/1461606/ffmpeg-ss-supported-formats-for-accurate-seeking-mp3-does-not-appear-to-work
[caps]: https://docs.gladia.io/reference/response-format
[`symphonia`]: https://docs.rs/symphonia/
[split-feature]: https://gladia-stt.nolt.io/23
[cap-api]: https://developers.google.com/youtube/v3/docs/captions/insert
[oa2]: https://developers.google.com/youtube/v3/guides/authentication
[oa2-impl]: https://github.com/ramosbugs/oauth2-rs/blob/main/examples/google.rs
[chunks]: https://datatracker.ietf.org/doc/html/rfc2616#section-3.6.1
[reqwest]: https://github.com/seanmonstar/reqwest/issues/1139
[run-example]: https://developers.google.com/explorer-help/code-samples#python
[py]: https://github.com/jonhoo/gladia-captions/blob/main/upload-captions.py
[my videos]: https://www.youtube.com/@jonhoo
[yt-bump]: https://support.google.com/youtube/contact/yt_api_form?hl=en
[opus]: https://gladia-stt.nolt.io/35

[^long-captions]: Gladia sometimes returns captions that are overly
    long. I haven't found it to be an outright problem (like YouTube
    rejecting the captions), it's just a bit awkward to read when it
    happens. It'd be nice if there was a way to limit the max caption
    length, so I've filed [a feature
    request](https://gladia-stt.nolt.io/13).

[^big-json]: The Gladia API returns a fairly big JSON payload because it
    also includes word-level timestamps. I didn't need those here, but
    there [isn't currently](https://gladia-stt.nolt.io/4) a way to omit
    them.

[^server-split]: It's a little unfortunate that the audio has to be
    split on the client side, especially given that the Gladia API
    supports providing YouTube URLs directly. It'd be so convenient if
    one could instead tell Gladia specifically which _part_ of the
    posted URL's audio to caption. So, I've filed [a feature
    request](https://gladia-stt.nolt.io/24).
