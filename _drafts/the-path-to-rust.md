---
layout: post
title: The Path to Rust
date: '2016-05-23 13:29:42'
---

About six months ago, I started my first large-scale Rust-based project.
I'd dabbled with the language in its early days, but back then it was a
different beast, and not particularly approachable. I decided to try
again, and I'm glad I did. Rust is quickly becoming my favorite language
for all systems work (which is most of what I do anyway), and has
largely replaced both Go, Python, and C/C++ in my day-to-day.

Rust helps you avoid a lot of silly mistakes while also being
expressive, flexible, and fast. However, that's not what is most
important to me. I *like* writing programs in Rust. It's the first time
in quite a long time that I am *excited* to be coding in a language ---
I actively *want* to convert old projects to Rust. YMMV of course, but I
urge you to give it a shot!

Rust is not the most beginner-friendly language out there --- the
compiler is not as lenient and forgiving as that of most other languages
(Go, I'm looking at you), and will regularly reject your code (albeit
usually for good reasons). This creates a relatively high barrier to
entry, even for people with extensive programming backgrounds. In
particular, Rust's "catch bugs at compile time" mentality means
that you often do not see partial progress --- either your program
doesn't compile, or it runs and does the right thing. Obviously, this is
not always true, but it can make it harder to learn by doing than in
other, less strict languages.

This post is not meant to be a comprehensive introduction to Rust. If
you want to learn Rust, you should go read the excellent [Rust
book](https://doc.rust-lang.org/book/). Instead, I will attempts to give
some pointers for developers coming from other systems languages (Go and
C in particular), and to point out tips, gotcha's, and shortcomings
along the way.

### How is Rust different?

When researching a new language, developers (like you, dear reader) will
inevitably focus on how the language in question is different from the
one they are currently using. In particular, they want to know whether
(and if so, how) the new languages is *better*.

The [Rust](https://www.rust-lang.org/) website has a list of Rust
"features", but that's not all that helpful if you're trying to decide
whether the new language is better *for you*.

How is it better?

 - As fast as C (low-level)
 - Compile-time checks for data races!
 - Extremely expressive (filter map collect -> HashMap?)
 - Expressive type system (enums, pattern matching if you missed smtg)
 - Lifetimes are neat (name(&'a Struct) -> &'a str)
 - *Awesome* community.

How is it worse?

 - No garbage collection == reference counting
 - Running code is (often much) harder
 - Sometimes hard to analyze perf (how efficient are iterators?)
 - CSP/Goroutines not as nice as in Go
 - Tools still young

### Tips & Gotchas

 - &*
 - flat map collect into iterator
 - iterate on sources
 - iterator count
 - if let else unreachable
 - chain some into iterator
 - impl on only one enum variant
