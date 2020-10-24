---
layout: post
title: "Using a real camera as a webcam on Linux"
date: '2020-10-15 17:50:01'
shared:
  Twitter: https://twitter.com/jonhoo/status/1316921179337334784
---

I've wanted to upgrade my video setup for a while now. The [Logitech
C920] I've been using is quite decent, but I figured that if I'm only
going to produce more video content going forward, the upgrade would be
worth it. And I figured that doing the upgrade _before_ I [record my
thesis defense](https://twitter.com/jonhoo/status/1315816753679622144)
might be a good idea.

Unfortunately, there aren't that many webcams that are "better" than the
C920. Some recommend the [Brio] or the [StreamCam] (this really seems to
be a Logitech market), but none of them appear to _that_ much of a step
up. Fundamentally, you can only get so far with a sensor and lens that
small.

Instead, the next step up is to get a "real" camera, and somehow hook
that up to your computer. This, of course, immediately raises a number
of questions: what is a real camera, which one do I get, and how do I
hook it up? In my case, I had the additional requirement that it work on
Linux, which tends to throw a wrench into things. Especially because
most streamers (it seems) use Windows or macOS. And so, it's adventure
time!

# Choosing a camera

When I say real camera, what I mean is a camera that's specifically
intended for shooting video "for real". There are four rough categories:

 - DSLRs: the big cameras with attached lenses that go "shkshk" when you take a photo.
 - Mirrorless: the slightly smaller cameras with attached lenses that play a "shkshk" sound when you take a photo.
 - Camcorders: long cameras you slot your hand through that are made for shooting video.
 - Action Cameras: things like GoPros.

Picking between these is hard, and there aren't obvious answers. I ended
up going for a mirrorless because: Action Cameras usually have really
wide angle lenses (which I didn't need), DSLRs [don't provide much
benefit in this context][dslrs], and camcorders are only slightly
cheaper than mirrorless but have worse image quality and can't be
upgraded with better lenses. I also found that it was easier to find
used mirrorless cameras for sale than it was to find camcorders.

Now, not everything is rosy with mirrorless cameras either, mostly
because they weren't really built for constantly streaming video. In
particular, you'll want to get a "dummy battery", which lets you hook
the camera into AC power so that it can run continuously. And those
aren't generally official supported by the manufacturers. That said,
looking around the internet, people seem to be using them with much
success.

Many "regular" cameras (as opposed to camcorders) also aren't designed
to output video to other devices. Luckily, many of them have HDMI out
(which we'll take advantage of), but often those are intended to be used
with external monitors, and not for actually recording anything. And as
a result, they often have a bunch of additional information on them that
is added by the camera; things like the current ISO, focus boxes,
shooting modes, etc. So, you'll have to specifically look for one that
does not have those, or has a way to shut them off. The search term
you want to use is "clean HDMI". There's a handy lookup tool
[here](https://www.elgato.com/en/gaming/cam-link/camera-check), though
it only covers relatively new devices.

When it comes to picking a particular make and model, there aren't
really any right answers. Your budget is going to mostly make the
decision for you. I highly recommend buying used, since cameras tend to
hold up pretty well, and still come at a significant discount. I ended
up going with the [Panasonic LUMIX G7], which supports 4k video, has
clean HDMI, seems to be generally liked and well-tested in the
community, and had some decent offers on ebay. Do note that the G7 does
_not_ focus automatically when it's just monitoring over HDMI, so you'll
have to hold down the capture button half-way to manually focus. And you
have to do that each time you turn it on. If you know of a way to avoid
that, let me know!

You'll also find yourself looking at lenses when you are considering a
mirrorless camera. Chances are you want one that's wide-angle to
replicate the feel of a webcam (at least that's what I wanted), in which
case you want "fewer mm". The G7 comes with a 14-42mm lens kit, and I'm
using it zoomed almost all the way out (so ~14mm). You can also get a
"prime" lens, which has better image quality, but doesn't zoom (in or
out), but that's probably not worth it if you're only dipping your toes
in the water with this.

# Hooking it up

So now you have this shiny new camera, and you need to set it up. And I
mean that in a "set up the cables and software" sense, but also in a
"physically place it in the right place" sense. The latter is a much
bigger hassle with a "real" camera, since it doesn't just nicely attach
to the top of your screen. Exactly what arrangement works best for you
may take some thinking, but I repurposed my [old mic boom] as a camera
boom, and then grabbed a ["ball head"] that would allow me to point the
camera. The camera attaches to the ball head, the ball head to the boom,
and the boom to the back of my desk near the monitor. It's not the
_most_ elegant setup, but it's cheap and I now have the camera exactly
where my webcam used to be.

Now, for the cables. The trick that most of these camera setups pull is
to run HDMI from the cable to an "HDMI capture card". The capture card
connects to your computer (usually either USB 3.0 or PCIe) and
gives you a way of "capturing" the HDMI signal through a program like
OBS. Of course, as will all external devices, whether one will work well
for you (especially on Linux) is a bit of a toss-up.

In my case, I wanted something that did not require me to install any
drivers, or otherwise fiddle with my kernel, because fewer parts means
fewer opportunities for problems. In the Linux world, that _basically_
means you want a capture card that supports [UVC], a standardized
protocol for manifesting video devices over USB. In fact, it's probably
what your webcam is using already! UVC devices are generally supported
right out of the box, and automatically appear on Linux as [V4L2
devices] (again, just like a webcam!). So, in theory, completely
hassle-free. I didn't find too many HDMI capture cards that used UVC,
but the [Elgato Cam Link] does. People also seemed to have some luck
with actually running it in practice on Linux from some cursory
searching, so I went with that one.

Actually hooking all of this up wasn't too bad. I got [this dummy
battery] and a random micro HDMI to HDMI cable, and after connecting
everything, the camera came on, and the light on the Elgato lit up.
There was even a `/dev/video0` device! So far so good. But when I
actually went to try looking at the webcam output (`ffplay
/dev/video0`), I got nothing. Hmm...

# Actually getting an image

I'll spare you the journey, and instead give you the conclusions. First,
I had to change a couple of settings on the camera. The little knob on
the right had to be set to P (others may also work), and the shooting
mode knob on the left had to be set to the single picture frame. Other
configurations may also work. Then, in settings, "Rec Format" had to be
set to MP4, and "HDMI Info Display" under "TV Connection" had to be set
to off. You can set "Rec Quality" to whatever you want, though I
recommend FHD/60p because:

Elgato [does not officially support Linux], and so various
configurations get a little wonky. In particular, the Elgato advertises
a number of different supported color modes even though the camera does
not support them. If you set the camera to output FHD for example, it
reports:

```console
$ v4l2-ctl -d /dev/video0 --list-formats-ext
ioctl: VIDIOC_ENUM_FMT
        Type: Video Capture

        [0]: 'YUYV' (YUYV 4:2:2)
                Size: Discrete 1920x1080
                        Interval: Discrete 0.017s (59.940 fps)
        [1]: 'NV12' (Y/CbCr 4:2:0)
                Size: Discrete 1920x1080
                        Interval: Discrete 0.017s (59.940 fps)
        [2]: 'YU12' (Planar YUV 4:2:0)
                Size: Discrete 1920x1080
                        Interval: Discrete 0.017s (59.940 fps)
```

But in practice, anything but YUYV will give you an empty or green
screen. If you're using this setup only in OBS this is fine, since you
can choose the color mode, but if you also want to use it as a webcam in
other applications, they will likely choose `NV12` and thus get a bad
signal. You can work around this using [this `LD_PRELOAD` script], which
isn't great, but seems to work for me. The source is easy to audit. You
can test that this'll work with

```console
$ ffplay -pixel_format yuyv422 /dev/video0
```

Worse yet, if you try to set the camera to any 4k output, that top
option is *also* listed as `Y/CbCr 4:2:0`  (which is a *different* bug),
and I don't know if the preload trick will work there.

I also found that the signal had a noticeable input lag (probably
~500ms). Many people complained that this happened if they connected the
Cam Link to a USB port that shared a bus with many other devices (check
`lsusb -tv`), but that wasn't the case in my setup. However, this lag
went away when the camera was set to output in 60 fps (and only then).
Which is super weird, since FHD/30 should send _less_ data over the
link, but it also had the added latency. Shrug. For the Panasonic G7,
this eliminated 4k input (which it can only do at 30fps), but I'm okay
with that. Hopefully one day that'll be fixed.

## Handy USB reset

I've found the Elgato to be really finicky about allowing you to start
and stop capturing. And it gets old really fast to have to plug it out
and back in between each time you want to record. It turns out you can
get around this really easily by doing a "soft" reset using [this
program](https://marc.info/?l=linux-usb&m=121459435621262&w=2). It looks
a little intimidating, but it really just issues an `ioctl`. There are
usage instructions
[here](https://askubuntu.com/questions/645/how-do-you-reset-a-usb-device-from-the-command-line),
though after you've compiled it (`cc usbreset.c -o usbreset`), it's
just:

```console
$ lsusb | grep Elgato
Bus 001 Device 002: ID 0fd9:0066 Elgato Systems GmbH Cam Link 4K
$ sudo ./usbreset /dev/bus/usb/001/002
```

And then you should be able to capture the video again just fine. I now
simply re-run this program every time I stop capturing so it'll be ready
again for next time. I wish I didn't have to, but I haven't had any
issues since I started doing that.

# Result

Which brings me to the end. It works! As for whether it looks better,
I'll let you be the judge. The pictures in this tweet were taken at
exactly the same time by my old webcam and my new camera which were set
up side-by-side:

<blockquote class="twitter-tweet" data-conversation="none"><p lang="en" dir="ltr">Just gave my webcam setup an upgrade. I think it got better. <a href="https://t.co/U1IvdM23a4">pic.twitter.com/U1IvdM23a4</a></p>&mdash; Jon Gjengset (@jonhoo) <a href="https://twitter.com/jonhoo/status/1316902940154728450?ref_src=twsrc%5Etfw">October 16, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet" data-conversation="none"><p lang="en" dir="ltr">And for anyone who&#39;s curious, here&#39;s the setup itself (with old webcam for comparison): <a href="https://t.co/vH2psKyhH5">pic.twitter.com/vH2psKyhH5</a></p>&mdash; Jon Gjengset (@jonhoo) <a href="https://twitter.com/jonhoo/status/1317169643467939840?ref_src=twsrc%5Etfw">October 16, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

  [Logitech C920]: https://www.logitech.com/en-us/products/webcams/c920-pro-hd-webcam.960-000764.html
  [Brio]: https://www.logitech.com/en-us/product/brio
  [StreamCam]: https://www.logitech.com/en-us/products/webcams/streamcam.960-001289.html
  [dslrs]: https://filmora.wondershare.com/youtube/mirrorless-vs-dslr.html#part4
  [Panasonic LUMIX G7]: https://shop.panasonic.com/cameras-and-camcorders/cameras/lumix-interchangeable-lens-ilc-cameras/DMC-G7K.html?dwvar_DMC-G7K_color=Black
  [old mic boom]: https://www.innogear.com/products/microphone-stand-mic-windscreen-and-mic-pop-filter-set
  ["ball head"]: https://smile.amazon.com/gp/product/B07RXQTL1V/ref=ppx_yo_dt_b_asin_title_o08_s00?ie=UTF8&psc=1
  [UVC]: https://www.ideasonboard.org/uvc/
  [V4L2 devices]: https://linuxdevices.org/intro-to-v4l2-a/
  [Elgato Cam Link]: https://www.elgato.com/en/gaming/cam-link-4k
  [this dummy battery]: https://smile.amazon.com/gp/product/B01D69P0UG/ref=ppx_yo_dt_b_asin_title_o08_s00?ie=UTF8&psc=1
  [does not officially support Linux]: https://github.com/xkahn/camlink#this-is-a-cam-link-bug-4k-what-does-elgato-support-say
  [this `LD_PRELOAD` script]: https://github.com/xkahn/camlink
