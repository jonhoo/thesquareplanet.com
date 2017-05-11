---
layout: post
title: The Story of a Rust Bug
date: '2017-05-10 23:23:23'
shared:
  Hacker News: https://news.ycombinator.com/item?id=14313854
  Twitter: https://twitter.com/Jonhoo/status/862527250817798144
  Lobsters: https://lobste.rs/s/7bnai0/story_rust_bug
  Reddit: https://www.reddit.com/r/rust/comments/6ai0ga/the_story_of_a_rust_bug_a_trip_down_a_rabbit_hole/
---

A while ago, I built a system-tray application in Rust to notify me of
new e-mail called [buzz](https://github.com/jonhoo/buzz). It was working
fine, but every now and again, it would fail to connect to the mail
server on boot if it started before my network connection was up. Sounds
easy enough to fix, so I just [added a loop][add-loop] around my connect
(even made it have exponential backoff!) and considered the issue dealt
with.

Fast forward a few days, and the same issue happens again. I boot my
computer, buzz starts before my network is ready, and while it now
continues trying to connect for a while, each attempt fails with the
same error: "Name or service not known". Hmm… I kill buzz and restart
it, and lo and behold it connects immediately without issue. What
sorcery is this?

It's time to do some debugging. First, let's write a sample program:

```rust
fn main() {
    use std::thread;
    use std::time::Duration;
    use std::net::TcpStream;

    loop {
        match TcpStream::connect("google.com:80") {
            Ok(_) => {
                println!("connected");
                break;
            }
            Err(e) => {
                println!("failed: {:?}", e);
            }
        }
        thread::sleep(Duration::from_secs(1));
    }
}
```

Running it prints "connected" --- great. Now, let's disconnect the
internet and run it again --- it prints

> failed: Name or service not known

over and over again. Okay, still as expected. Now let's turn the
internet back on

> failed: Name or service not known<br />
> failed: Name or service not known<br />
> failed: Name or service not known<br />
> failed: Name or service not known

Something is definitely fishy. So, let's ask Google:

> linux c connect before interface comes up and then retry

No particularly promising results there...

> linux c connect before interface comes up and then retry Name or service not known

Still unhelpful.

> linux internet connectivity retry connection failed

This takes us to a somewhat promising Thunderbird issue named
"[Thunderbird "Failed to connect to server" after connecting to
Internet][tbird]", but it fails to reach any helpful conclusions. But we
shall not surrender!

> "Name or service not known" after interface comes up

Ooooh, "[#2825 (Pidgin cannot reconnect after changing
networks)][pidgin]" looks promising. Among the comments:

> This is an issue when NetworkManager isn't around. `res_init` (rereads
> `/etc/resolv.conf`) is only called in the NM path.

`/etc/resolv.conf` is where Linux keeps track of the DNS nameservers to
use when looking up the IP addresses of domain names. Depending on your
network configuration, that file is *empty* when you are offline, and
then entries are filled in when you connect to a network. The comment
suggests that the contents of this file is *cached*, which would mean
our program never learns of any nameservers (it always see the empty
list), and so all DNS resolution fails for all eternity!

Armed with the knowledge about `res_init`, our Google searches are
suddenly a lot more helpful, and reveal that this problem is actually
something many projects [have][mozilla] [encountered][mongo]. Let's see
what Rust does, why our program doesn't work, and how we might fix it.

[`TcpStream::connect`] takes an argument that implements
[`ToSocketAddrs`]. "Implementors" at the bottom of that page shows that
`ToSocketAddrs` is implemented for `str`, which makes a lot of sense
given that we're passing in a `str` to it in our code above. Let's click
the [`src`] link at the top right of the page to see what it's doing
to turn that string into an IP address!

Scrolling down [a little], we see that it calls `resolve_socket_addr`,
which is defined a bit [further up]. It again calls [`lookup_host`],
which seems to just be a stub of some sort:

```rust
use sys_common::net as net_imp;
// ...
pub fn lookup_host(host: &str) -> io::Result<LookupHost> {
    net_imp::lookup_host(host).map(LookupHost)
}
```

That's not very helpful. It's time we go explore the rust [GitHub
repository][rust]. There's a *lot* of stuff here, but let's just try to
take the fast path to what we're looking for. The `use sys_common::net`
gives us a starting point: `use` statements like these inside the
standard library are using other modules from the standard library,
which lives in [`src/libstd`]. And how about that, right there there's a
little [`sys_common`] subdirectory. Let's open that up. And then we want
[`net.rs`], because that's the module the `lookup_host` function was
using.

(At this point, it's worth noting that I've cheated a little. Since my
fix for this bug has now landed, if you actually follow the path on
GitHub, you'll see [the new version of `net.rs`][fixed]. If you want to
see what I saw, click the linked `net.rs` above instead.)

So, `lookup_host` calls `c::getaddrinfo`, and then returns `Ok`. There's
a call to `cvt_gai` in there suffixed with a `?`, which I assume deals
with the case where the lookup fails, but let's ignore that for a
second. There's no call to `res_init` here. This means that unless the
application calls `res_init` itself, it will simply never get to use the
internet. That's pretty sad. Let's fix that!

The most straightforward fix is to just call `res_init` directly from
our application if `connect` fails. But, in order to do that, we, well,
need to be able to call `res_init`. [`res_init`] is a function in libc
(at least on UNIX-like systems), so the place to look would be the Rust
[`libc` crate]. If you look today, there *is* a `res_init` function in
`libc`, but this was *not* the case when I looked. So, time to file a
pull request!

The `libc` README clearly states the process for [adding an API], and it
basically comes down to "add a function to `src/unix/mod.rs`, submit,
and then fix failing tests". It turns out that `res_init` is actually
somewhat funky as far as libc functions go, so it took quite a bit of
digging to get it right on all the UNIX-y platforms that libc supports.
But with the aid of the amazing [Alex Crichton][alex], green checkmarks
eventually started appearing, and [PR#585] landed (if you want to know
what the process is like, I encourage you to read through the comments
there).

Okay, so we now have `libc::res_init`, which means we can fix our
application by adding a dependency on `libc` and calling the function
manually after each failed connection attempt. While this would work, it
doesn't feel particularly elegant. And what about other people who will
inevitably also run into the same issue? No, we can to better. Time to
fix Rust!

First, I filed [#41570], an issue outlining the issue, giving much of
the same reasoning and examples that I've given in this post. I actually
did that *before* my libc PR, but that's sort of beside the point. I
then asked for opinions about what the best place to implement the fix
would be, suggesting the `lookup_host` function we found above. Alex
Crichton responded (again!), and [PR#41582] was born. I'll spare you
some of the details (read the comments if you want them), but two
primary changes were needed:

 - We had to update the version of `libc` that rust includes, so that we
   have access to the newly added `res_init`. `libc` is linked into rust
   as a [git submodule], so that was just a matter of `cd`-ing into the
   right directory and running `git pull`.
 - We then had to [modify `lookup_host`][mod] so that, if it fails to do
   a lookup, and we're running a UNIX-y OS, we call `res_init` before
   returning.

It took a few iterations to get the kinks ironed out, and all os targets
to be happy, but on May 5th at 5:35pm, the [Rust build system][homu]
accepted and merged my PR! A few hours later, at midnight UTC, a new
nightly release of Rust was published, which included my fix. After a
quick `rustup update` and a recompile, `buzz` now works correctly
without any changes to the code! Yay progress!

Hopefully this post has given some insight into what is involved in
making a contribution to the Rust standard library, and may give you
some pointers to what you might do if you find something *you* would
like to fix in Rust! It doesn't even have to involve coding --- the Rust
team would love [documentation changes] too. Happy hacking!

[add-loop]: https://github.com/jonhoo/buzz/commit/90b1602ad1c2d6a1c3836efb2dfe11d8157c2255#diff-639fbc4ef05b315af92b4d836c31b023R131
[tbird]: https://bugzilla.mozilla.org/show_bug.cgi?id=656072
[pidgin]: https://developer.pidgin.im/ticket/2825
[mozilla]: https://bugzilla.mozilla.org/show_bug.cgi?id=214538
[mongo]: https://jira.mongodb.org/browse/DOCS-5700
[`TcpStream::connect`]: https://doc.rust-lang.org/std/net/struct.TcpStream.html#method.connect
[`ToSocketAddrs`]: https://doc.rust-lang.org/std/net/trait.ToSocketAddrs.html
[`src`]: https://doc.rust-lang.org/src/std/net/addr.rs.html#619-638
[a little]: https://doc.rust-lang.org/src/std/net/addr.rs.html#722-747
[further up]: https://doc.rust-lang.org/src/std/net/addr.rs.html#694
[`lookup_host`]: https://doc.rust-lang.org/std/net/fn.lookup_host.html
[rust]: https://github.com/rust-lang/rust
[`src/libstd`]: https://github.com/rust-lang/rust/tree/master/src/libstd
[`sys_common`]: https://github.com/rust-lang/rust/tree/master/src/libstd/sys_common
[`net.rs`]: https://github.com/rust-lang/rust/blob/4961d724f8d02870087c1912a55378458b0d6a90/src/libstd/sys_common/net.rs#L164-L184
[fixed]: https://github.com/rust-lang/rust/blob/bb8d51c2ebe8d89c9cdcf06a9383d6e974efc5b6/src/libstd/sys_common/net.rs#L164-L197
[`res_init`]: https://linux.die.net/man/3/res_init
[`libc` crate]: https://github.com/rust-lang/libc
[adding an API]: https://github.com/rust-lang/libc#adding-an-api
[alex]: https://github.com/alexcrichton
[PR#585]: https://github.com/rust-lang/libc/pull/585
[#41570]: https://github.com/rust-lang/rust/issues/41570
[PR#41582]: https://github.com/rust-lang/rust/pull/41582
[git submodule]: https://git-scm.com/book/en/v2/Git-Tools-Submodules
[mod]: https://github.com/rust-lang/rust/pull/41582/files#diff-2
[homu]: https://buildbot2.rust-lang.org/homu/queue/all
[documentation changes]: https://github.com/rust-lang/rust/issues/29370
