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
C/C++ in particular), and to point out tips, gotcha's, and shortcomings
along the way.

### How is Rust better for me?

When researching a new language, developers (like you, dear reader) will
inevitably focus on how the language in question is different from the
one they are currently using. In particular, they want to know whether
(and if so, how) the new languages is *better*. The
[Rust](https://www.rust-lang.org/) website has a list of Rust
"features", but that's not all that helpful if you're trying to decide
whether the new language is better *for you*. So, let's go through some
of the ways Rust might make your life easier.

#### Fewer runtime bugs

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

#### Safe concurrency

This latter point is particularly interesting; the Rust compiler *will
not* compile a program that has a potential race condition in it. Unless
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

#### Performance without sacrifice

Some of the bugs found by the Tor developers are handled in other
higher-level languages as well. Unfortunately, higher-level languages
are often not a great fit for systems code. Systems code is often
performance critical (e.g., kernels, databases), so the developer wants
predictable performance, and tight control over memory
allocation/de-allocation and data layout. This can be hard to achieve in
higher-level languages or when using a garbage collector.

Rust provides features that are often associated with high-level
languages (such as automatic memory `free`-ing when values go out of
scope, pattern matching, functional programming abstractions, a powerful
type system), as well as powerful features like the borrow checker, with
*no runtime cost*. This might seem too good to be true (and it
admittedly still feels that way to me), but Rust's claim to achieve
performance comparable to that of C++ seems to be supported in
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

#### Expressivity and productivity

One of the reasons developers often report to be more productive in
higher-level languages is the availability of higher-level primitives.
Consider the case of constructing an inverted index for a given string.
In C (or C++), you might write something like
[this](https://www.rosettacode.org/wiki/Inverted_index#C.2B.2B). Let's
have a look at the same code in Rust:

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

Not only is this very readable, it is also reasonably efficient (each
file is processed as a stream), terminates nicely with an error if a
file could not be opened, and exits cleanly if the user closes the input
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
  struct User u;
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

#### A great build system

- Cargo deps
- Doc and tests built in (like Go, but better)
- Good documentation, and getting better (link to relevant comparisons
  with Go/C++ docs)

### Why would I not choose Rust?

 - Still young, so many things don't exist.
 - No garbage collection == reference counting
 - Getting to running code is often (much) harder
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
