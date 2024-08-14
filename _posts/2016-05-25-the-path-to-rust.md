---
layout: post
title: The Path to Rust
date: '2016-05-25 17:34:42'
shared:
  Hacker News: https://news.ycombinator.com/item?id=11774850
  Twitter: https://twitter.com/Jonhoo/status/735585362626646017
  Reddit: https://www.reddit.com/r/rust/comments/4l221l/the_path_to_rust_why_rust_might_be_right_for_you/
  Lobsters: https://lobste.rs/s/ly3tlt/path_rust
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
book](https://doc.rust-lang.org/book/). Instead, I will attempt to give
an evaluation of Rust for developers coming from other systems languages
(Go and C/C++ in particular), and to point out why they may or may not
want to try Rust. At the end, I'll also point out some tips and
gotcha's, at the end for those who are interested in that kind of stuff.

# Why is Rust better for me?

When researching a new language, developers (like you, dear reader) will
inevitably focus on how the language in question is different from the
one they are currently using. In particular, they want to know whether
(and if so, how) the new languages is *better*. The
[Rust](https://www.rust-lang.org/) website has a list of Rust
"features", but that's not all that helpful if you're trying to decide
whether the new language is better *for you*. So, let's go through some
of the ways Rust might make your life easier.

## Fewer runtime bugs

> If debugging is the process of removing bugs, then programming must be
> the process of putting them in.
>
> <cite>Edsger W. Dijkstra [citation needed]</cite>

Code is very rarely correct the first time it is written, especially for
complex systems code. Even for seasoned developers, a large portion of
programming time is spent debugging why code *doesn't* do what it's
supposed to.

One of the Tor developers recently did [a
retrospective](https://blog.torproject.org/blog/mid-2016-tor-bug-retrospective-lessons-future-coding)
on what kinds of bugs had crept into the Tor onion router over the past
couple of years, as well as how they could have been avoided. While
reading through the list of identified issues, I noticed that many of
these would be caught *at compile-time* in Rust. To note a few:

- 2.1 would be caught by Rust's overflow detection.
- 2.2 would be a non-issue in Rust --- `void*` is not available, and the
  more expressive type system (generics for example) would render them
  unnecessary anyway.
- 2.4 speaks for itself.
- 3.1: Rust's lifetimes are designed to address exactly this issue.
- 3.3: Pattern matching in Rust (think of it as a `switch` on steroids)
  is checked for completeness (i.e., all possible cases are handled)
  at compile-time.
- 4.1: Propagating `Result`s with `try!` is a common pattern in Rust,
  which would effectively provide exactly this kind of behavior.
- 9.1: Rust has strong conventions for return values that can return
  errors (basically, use `Result`), and callers *must* deal with the
  fact that a function can error.
- 10.2/10.3: Rust's borrow checker enforces that data can't be
  simultaneously read and written, making this kind of bug impossible.

Go, which has increasingly been adopted as a systems language, solves
some of these issues, but far from all. It also introduces its own set
of issues, such as type-casting from the `interface{}` type or data
races between Goroutines, which are non-existent in Rust.

## Safe concurrency

This latter point is particularly interesting; the Rust compiler *will
not* compile a program that has a potential data race in it. Unless
you explicitly mark your code as `unsafe` (which you rarely, if ever,
need to do), your code simply cannot have data races. Rust checks this
using the **borrow checker**, which enforces [two simple
rules](https://doc.rust-lang.org/book/references-and-borrowing.html#the-rules):

> First, any borrow must last for a scope no greater than that of the
> owner. Second, you may have one or the other of these two kinds of
> borrows, but not both at the same time:
>
> - one or more references (`&T`) to a resource,
> - exactly one mutable reference (`&mut T`).

The first rule ensures that you never use a value after it has gone out
of scope (eradicating use-after-free and double-free in one fell swoop).
The second rule guarantees that you have no data races, since you cannot
have two mutable references to the same data, nor can you have one
thread modify while another thread reads. This might seem restrictive at
first, but all the solutions you would use to avoid races in regular
code are fully supported, and their correctness is checked *at
compile-time*: you can add
[locks](https://doc.rust-lang.org/std/sync/struct.Mutex.html) to allow
two threads mutable access to a variable, or use [atomic
operations](https://doc.rust-lang.org/std/sync/atomic/index.html) to
implement RCU and other algorithms that allow concurrent reads and
writes.

## Performance without sacrifice

Some of the bugs found by the Tor developers are handled in other
higher-level languages as well. Unfortunately, higher-level languages
are often not a great fit for systems code. Systems code is often
performance critical (e.g.,
[kernels](http://www.redox-os.org/index.html), databases), so the
developer wants predictable performance, and tight control over memory
allocation/de-allocation and data layout. This can be hard to achieve in
higher-level languages or when using a garbage collector.

Rust provides features that are often associated with high-level
languages (such as automatic memory `free`-ing when values go out of
scope, pattern matching, functional programming abstractions, a powerful
type system), as well as powerful features like the borrow checker, with
*no runtime cost*. This might seem unbelievable (and it admittedly still
feels that way to me), but Rust's claim to achieve performance
comparable to that of C++ seems to be supported in
[multiple](https://benchmarksgame.alioth.debian.org/u64q/compare.php?lang=rust&lang2=gpp)
[benchmarks](http://cantrip.org/rust-vs-c++.html).

Furthermore, Rust gives the developer control over when memory is
allocated, and how it is [laid
out](https://doc.rust-lang.org/nomicon/repr-rust.html). This in turn
allows straightforward and efficient interaction with C APIs (and other
languages) through the [Foreign Function
Interface](https://doc.rust-lang.org/book/ffi.html), and makes it easy
to interact with high-performance libraries like BLAS, or low-level
toolkits like [DPDK](http://dpdk.org/), which may not be available
natively in Rust (yet).

## Expressivity and productivity

One of the reasons developers often report to be more productive in
higher-level languages is the availability of higher-level primitives.
Consider the case of constructing an inverted index for a given string.
In C (or C++), you might write something like
[this](https://www.rosettacode.org/wiki/Inverted_index#C.2B.2B) (there
are examples in other languages there too).

Let's have a look at how you might implement something similar in Rust.
Note that it's not actually the same as the C++ example, since that also
implements a Trie. For a more apples-to-apples comparison, consider
[this](http://pastebin.com/VwMT38Tg)
C++ variant written by a
[Redditor](https://www.reddit.com/r/programming/comments/4l3uhn/the_path_to_rust/d3kffvk).

```rust
fn main() {
  use std::io;
  use std::fs;
  use std::env;
  use std::collections::{HashMap, HashSet};
  use std::io::BufRead;

  let args = env::args().skip(1).collect::<Vec<_>>();
  let idx = args
    // iterate over our arguments
    .iter()
    // open each file
    .map(|fname| (fname.as_str(), fs::File::open(fname.as_str())))
    // check for errors
    .map(|(fname, f)| {
      f.and_then(|f| Ok((fname, f)))
        .expect(&format!("input file {} could not be opened", fname))
    })
  // make a buffered reader
  .map(|(fname, f)| (fname, io::BufReader::new(f)))
    // for each file
    .flat_map(|(f, file)| {
      file
        // read the lines
        .lines()
        // split into words
        .flat_map(|line| {
          line.unwrap().split_whitespace()
            .map(|w| w.to_string()).collect::<Vec<_>>().into_iter()
	    // NOTE: the collect+into_iter here is icky
	    // have a look at the flat_map entry
	    // in the Appendix for why it's here
        })
      // prune duplicates
      .collect::<HashSet<_>>()
        .into_iter()
        // and emit inverted index entry
        .map(move |word| (word, f))
    })
  .fold(HashMap::new(), |mut idx, (word, f)| {
    // absorb all entries into a vector of file names per word
    idx.entry(word)
      .or_insert(Vec::new())
      .push(f);
    idx
  });

  println!("Please enter a search term and press enter:");
  print!("> ");

  let stdin = io::stdin();
  for query in stdin.lock().lines() {
    match idx.get(&*query.unwrap()) {
      Some(files) => println!("appears in {:?}", files),
      None => println!("does not appear in any files"),
    };
    print!("> ");
  }
}
```

If you are familiar with functional programming, you might find the above
both readable and straightforward. If you aren't, you [can
substitute](https://news.ycombinator.com/item?id=11775860) the
expression starting at `let idx =` above with:

```rust
let mut idx = HashMap::new();
for fname in &args {
  let f = match fs::File::open(fname) {
    Ok(f) => io::BufReader::new(f),
    Err(e) => panic!("input file {} could not be opened: {}", fname, e),
  };
  let mut words = HashSet::new();
  for line in f.lines() {
    for w in line.unwrap().split_whitespace() {
      if words.insert(w.to_string()) {
          // new word seen
          idx.entry(w.to_string()).or_insert(Vec::new()).push(fname);
      }
    }
  }
}
```

Crucially, these are *both* valid Rust programs, and you can mix and
match between the different styles as you want (you can see more
examples in the Hacker News discussion linked to at the top of this
post). Furthermore, both result in reasonably efficient code (each file
is processed as a stream), terminate nicely with an error if a file
could not be opened, and exit cleanly if the user closes the input
stream (e.g., with `^D`).

The code above shows examples of functional programming and pattern
matching in Rust. These are neat, but you can approximate something
similar in many other languages. One feature that is relatively unique
to Rust, and also turns out to be really useful, is lifetimes. Say, for
example, that you want to write a helper function that returns the
first and last name of a `struct User` that contains the user's full
name. You don't want to copy strings unnecessarily, and instead just
want pointers into the existing memory. Something along the lines of:

```c
#include <string.h>
#include <stdio.h>

struct User {
  char full_name[255];
};

char* first_name(struct User *u) {
  return strtok(u->full_name, " ");
}
char* last_name(struct User *u) {
  char *last = strrchr(u->full_name, ' ')+1;
  return last;
}

int main() {
  struct User *u = malloc(sizeof(struct User));
  strcpy(u.full_name, "Jon Gjengset");
  char* last = last_name(&u);
  char* first = first_name(&u);
  // ...
  printf("first: %s, last: %s\n", first, last);
  return 0;
}
```

The caller now has three pointers into `struct User`, `first`, `last`,
and `u`. What happens if the program now calls `free(u)` and tries to
print `first` or `last`? Oops. Since C strings are null-terminated, the
code also breaks `u->full_name` once `first_name` has been called,
because `strtok` will replace the first space in the string with a null
terminator.

Let's see what this code would look like in Rust:

```rust
struct User {
  full_name: String,
}

impl User {
  fn first_name<'a>(&'a self) -> &'a str {
    self.full_name.split_whitespace().next().unwrap()
  }
  fn last_name<'a>(&'a self) -> &'a str {
    self.full_name.split_whitespace().last().unwrap()
  }
}

fn main() {
  let u = User { full_name: "Jon Gjengset".to_string() };
  let first = u.first_name();
  let last = u.last_name();
  println!("first: {}, last: {}", first, last);
}
```

Notice the weird `'a` thing? That's a Rust lifetime. For `first_name`
and `last_name`, it says that the returned string reference (`&str`)
*can't outlive* the reference to `self`. Thus, if the programmer tried
to call `drop(u)` (Rust's equivalent of an explicit free), the compiler
would check that they did not later try to use `first` or `last`. Pretty
neat! Also, since Rust strings aren't null-terminated (array references
instead store their length), we can safely use `u.full_name` after
calling `first_name`. In fact, the caller *knows* that this is safe,
because `first_name` takes an *immutable* reference (`&`) to the object,
and thus *can't* modify it.

## A great build system

Rust comes with a build tool called
[Cargo](http://doc.crates.io/guide.html). Cargo is similar to `npm`, `go
get`, `pip` and friends; it lets you declare dependencies and build
options, and then automatically fetches and builds those when you build
your project. This makes it easy for yourself and others to build your
code, including third-party testing services like Travis.

Cargo is pretty featureful compared to many of its siblings in other
languages. It has versioned dependencies, supports multiple build
profiles (e.g., debug vs. release), and can even [link against C
code](http://doc.crates.io/faq.html#will-cargo-work-with-c-code-or-other-languages).
It also has built-in support for uploading and updating packages on
[crates.io](https://crates.io/), generating documentation, and running
tests.

These latter two points are worth elaborating on. First, Rust makes
writing documentation very easy. Comments that start with three slashes
(i.e., `///` instead of `//`) are documentation comments, and are
automatically associated with the following statement. The contents are
rendered as Markdown, and code examples are *automatically compiled and
run as tests*. The idea is that code examples should always build (of
course, you can override this for any given code block), and if it
doesn't, that should be considered a test failure. The rendered
documentation automatically links between different modules (including
the standard library documentation), and is really easy to use.

Most of the standard library has been very well documented by now, and
thanks to the ease of writing documentation, most of the available Rust
crates (the name of Rust packages) are also pretty well covered (have a
look at the documentation for this [Rust SQL ORM
crate](http://docs.diesel.rs/diesel/index.html) for example). In many
cases, the Rust documentation is even better than the documentation for
similar C++ or Go features --- for example, compare Rust's
[`Vec`](https://doc.rust-lang.org/std/vec/struct.Vec.html), C++'s
[`std::vector`](http://www.cplusplus.com/reference/vector/vector/), and
Go's [slices](https://golang.org/doc/effective_go.html#slices)
([part2](https://golang.org/ref/spec#Appending_and_copying_slices),
[part3](https://golang.org/ref/spec#Making_slices_maps_and_channels),
[part4](https://golang.org/ref/spec#Length_and_capacity)).

# Why would I not choose Rust?

By now, I hope I have convinced you that Rust has some pretty attractive
features. However, I bet you are still thinking "okay, but it can't all
be rainbows and roses". And you are right. There are some things that
you might dislike about Rust.

First, Rust is still [fairly
young](http://blog.rust-lang.org/2016/05/16/rust-at-one-year.html), and
so is its ecosystem. The Rust team has done an excellent job at building
a welcoming community, and the languages is [improving
constantly](https://github.com/rust-lang/rfcs), but Rome wasn't built in
a day. There are still some
[unfinished](https://github.com/rust-lang/rust/issues/27800)
[features](https://github.com/rust-lang/rust/issues/27700) in the
language itself (although [surprisingly
few](https://github.com/rust-lang/rust/search?utf8=✓&q=unstable+path%3A%2Fsrc%2Flibstd&type=Code)),
and some documentation [is still
missing](https://github.com/rust-lang/rust/issues/29329) (though
this is being [rapidly
addressed](https://guillaumegomez.github.io/this-week-in-rust-docs/)). A
number of [useful](https://github.com/aturon/crossbeam)
[libraries](https://github.com/japaric/criterion.rs) are still in their
early stages, and the tools for the ecosystem are still
[being](https://github.com/rust-lang-nursery/rustfmt)
[developed](https://github.com/rust-lang-nursery/rustup.rs). There is a
lot of interest and engagement from developers though, so the situation
is improving daily.

Second, since Rust is not garbage collected, there will be times when
you have to fall back to [reference
counting](https://doc.rust-lang.org/std/sync/struct.Arc.html), just like
you have to do in C/C++. Closely related is the fact that Rust does not
have **green threads** similar to Go's goroutines. Rust
[dropped](https://github.com/rust-lang/rfcs/pull/230) green threads
early on in favor of moving this to an [external
crate](https://doc.rust-lang.org/0.11.0/green/), which means the
integration is not as neat as it is in Go. You can still spawn threads,
and the borrow checker will prevent your from much of the nastiness of
concurrency bugs, but these will essentially be pthreads, not CSP-style
co-routines.

Third, Rust is a fairly complex language compared to C or Go (it's
more comparable to C++), and the compiler is a lot pickier. It can be
tricky for a newcomer to the language to get even relatively simple
programs to compile, and the learning curve remains steep for quite some
time. However, the compiler usually gives extremely helpful feedback
when your code doesn't compile, and the community is very friendly and
responsive (I suggest visiting
[#rust-beginners](https://client00.chat.mibbit.com/?server=irc.mozilla.org&channel=%23rust-beginners)
when you're starting out). Furthermore, once your code compiles, you'll
find (at least I have) that it is much more likely to be correct (i.e.,
do the right thing) than if you tried to write similar C, C++, or Go
code.

Finally, compared to C (and to some extent C++), Rust's complexity can
also make it harder to
[understand](https://github.com/rust-lang/rust/issues/33038)
[exactly](https://github.com/rust-lang/rust/labels/I-slow) what the
runtime behavior of your code is. That said, as long as you write
idiomatic Rust code, you'll probably find that your code turns out to be
as fast as you can expect in most cases. With time and practice,
estimating the performance of your code also becomes easier, but it is
certainly trickier than in simpler languages like C.

# Concluding remarks

I've given you what I believe to be a pretty fair and comprehensive
overview of Rust compared to C and Go, based on my experience from the
past six months. Rust has impressed me immensely, and I urge you to give
it a shot. This is especially true if you tried it a while ago and
didn't like it --- the language has matured *a lot* over the past year!
If you can think of additional pros and cons for switching to Rust,
please let me know either in HN comments, on Twitter, or by e-mail!

# Appendix A: Tips & Gotchas

- `String` [deref](https://doc.rust-lang.org/std/ops/trait.Deref.html)s
  to `&str`, and through [**deref
  coercion**](https://doc.rust-lang.org/book/deref-coercions.html) you
  can call all the methods on `&str` directly on a `String`. This is
  neat, but there is one case where it doesn't work as you'd hope: if
  you use a `String` to index into a `HashMap` where the keys are
  `&str`. This is because `Deref` is defined on `&String`, not `String`.
  You can prefix your `String` with a `&` when using it inside `[]` to
  overcome this. In general, you can also get a `&str` of a `String` by
  prefixing it with `&*`, which comes in handy at times.

- If you ever use `flat_map`, you may get weird lifetime complains from
  the compiler about the thing you are iterating over inside the
  `flat_map` closure not living long enough. This is usually because you
  have an `IntoIter` (i.e., an iterator that owns what it's iterating
  over), and since iterators are lazily evaluated, the owned value may
  no longer exist by the time the closure runs. The easiest (though not
  most efficient) way to overcome this is to write your code like this:

  ```rust
  // ...
  .flat_map(|e| {
    e.into_iter()
     .map(|ee| {
       // ...
     })
     .collect::<Vec<_>>().into_iter()
  })
  // ...
  ```

  The `collect` forces the iterator to be evaluated immediately,
  executing the closure. The resulting list is then converted to an
  iterator with no borrows, which can safely be returned by the
  `flat_map` closure without lifetime issues.

- If you have an iterator and you want to add an element (say `1`) to
  the end, you can do this using the following trick:

  ```rust
  for x in iter.chain(Some(1).into_iter()) {}
  ```

  This exploits the fact that an `Option` can be turned into an
  iterator, and chains that single-element iterator onto the existing
  one, giving you an iterator that yields an extra element after the
  original iterator ends.

- Since the
  [removal](https://doc.rust-lang.org/book/deref-coercions.html) of
  `thread::scoped`, it has become tricky to spawn threads that borrow
  from their environment. This is often useful if you want to run a pool
  of workers that need to share access to some resource. You can often
  get around this using reference counting, but that's not always a
  desirable option. Instead, you should use the [scoped-pool
  crate](https://github.com/reem/rust-scoped-pool), which supports
  scoped workers, or
  [`crossbeam::spawn`](https://aturon.github.io/crossbeam-doc/crossbeam/struct.Scope.html#method.spawn)
  which provides the same functionality without requiring a pool.

- Rust currently (as far as I'm aware) does not have a nice way of
  talking about only one variant within an enum. That is, you cannot
  write a function that operates on only a particular enum variant, or
  have a variable that Rust *knows* is of a particular variant. This
  can lead to a bunch of code along the lines of:

  ```rust
  if let MyEnum::ThisVariant(x) = x {
    // do something with x
  } else {
    unreachable!();
  }
  ```

  The `try!` macro and the `unwrap()`/`expect()` methods mitigate this
  pain when working with `Result` or `Option` types, but do not
  generalize. If anyone knows of a cleaner way of dealing with this,
  please let me know!
