---
layout: post
title: Rust tips &amp; tricks
date: '2016-10-20 20:16:20'
---

Rust has been seeing increased adoption, both in academia and industry,
over the past few months. This is great news for the language and its
community. However, it inevitably also means that a number of people
with relatively little experience in Rust are exposed to Rust codebases,
and, in many cases, are asked to modified them.

As programmers, when we start using a new language, we often carry over
the isms of the languages we already know into our new code. We don't
know how to write idiomatic code, and don't know the many convenient
shortcuts the language provides, but we make do and fiddle with things
until the program compiles and runs.

This is perfectly natural. Over time, by seeing other people's code, we
learn, we adapt, and we write better code. This post tries to speed up
that process by showing you some of the Rust shorthands I have
discovered so far.

### Returning values

In Rust, functions, conditionals, matches, and blocks all automatically
return the value of their last expression. Thus, instead of this:

```rust
impl Bar {
    fn get_baz(&self) -> &str {
        return self.baz;
    }
}
```

You can use:

```rust
impl Bar {
    fn get_baz(&self) -> &str {
        self.baz
    }
}
```

This is particularly useful for closures:

```rust
let words = vec!["hello", "world"];
let word_len = words.into_iter().map(|w| {
    return w.len();
}).collect();
```

Can be rewritten as

```rust
let words = vec!["hello", "world"];
let word_len = words.into_iter().map(|w| w.len()).collect();
```

### Things that can't happen (yet)

While writing code, you often reach an edge case (or maybe even a common
code path) that you aren't ready to deal with just yet. In other
languages, you might just write `return 0`, `exit(1)`, `assert(false)`,
or something similar. In Rust, there is a standard way to deal with this
case: `unimplemented!()`. This function (well, macro) halts your program
when invoked, prints a stack trace saying "reached unimplemented code",
and points you directly to the line in question.

Similarly, if you have a conditional that simply shouldn't be reachable,
you can use the semantically appropriate `unreachable!()`, which has a
similar effect as calling `unimplemented!()`.

### Taming Options

Imagine someone just passed you an `Option` that you *know* is `Some`,
and you want to look at what's inside it. Easy, you say, all the
tutorials told me that I can just use `unwrap()`:

```rust
struct Bar { opt: Option<String> };
impl Bar {
    fn baz(&self) {
        assert!(self.opt.is_some());
	let s = self.opt.unwrap();
    }
}
```
```
error[E0507]: cannot move out of borrowed content
 --> x.rs:5:17
  |
5 |         let s = self.opt.unwrap();
  |                 ^^^^ cannot move out of borrowed content
```

Damn. You are only borrowing the `Option` (i.e., you have an `&Option`),
so you can't call `unwrap()` (which moves the value out of the option).
Fine fine, you say. I'll use `unreachable!()` like you taught me:

```rust
impl Bar {
    fn baz(&self) {
        if let Some(ref s) = self.opt {
	    // do something with s
	} else {
	    unreachable!();
	}
    }
}
```

That compiles, but it doesn't look very nice, and you're left with an
extra level of indentation. Isn't there a better way? I'm glad you
asked:

```rust
impl Bar {
    fn baz(&self) {
        assert!(self.opt.is_some());
	let s = self.opt.as_ref().unwrap();
    }
}
```

The magical method `as_ref()` has the helpful signature `&Option<T> ->
Option<&T>`. That is, it turns a reference to an `Option` into an
`Option` that holds a reference. Perfect!

### Updating or inserting into a map

If you write code that's anything like what I write, you use maps all
over the place. `HashMap`s in particular. If you're filling the map, you
might write code like:

```rust
let mut map: HashMap<_, Vec<_>> = HashMap::new();
for (key, val) in vals.into_iter() {
    if let Some(mut vals) = map.get_mut(&key) {
        vals.push(val);
        continue;
    }
    map.insert(key, vec![val]);
}
```

Ugh. Isn't there a better way? Yes! Say hello to the [`Entry`
API](https://doc.rust-lang.org/std/collections/hash_map/enum.Entry.html).

```rust
let mut map = HashMap::new();
for (key, val) in vals.into_iter() {
    map.entry(key).or_insert_with(Vec::new).push(val);
}
```

Better? I'd say so.

### Omitting types

If you've ever used `.collect()`, you've probably come across this
error:

```
error[E0282]: unable to infer enough type information about `_`
 --> collect.rs:2:37
  |
2 |     let numbers = (0..10).collect();
  |         ^^^^^^^ cannot infer type for `_`
  |
  = note: type annotations or generic parameter binding required
```

Well, of course I wanted a `Vec` Rust?! What else [could I
possibly](https://doc.rust-lang.org/std/iter/trait.FromIterator.html#implementors)
have wanted to collect into? You *might* know that you can tell Rust by
doing:

```rust
let numbers = (0..10).collect::<Vec<isize>>()
```

But did you also know that you can use our friend `_` to have Rust
complete the type for you?

```rust
let numbers = (0..10).collect::<Vec<_>>()
```

You can even make the code read better by doing:

```rust
let numbers: Vec<_> = (0..10).collect();
```

<!-- ### Extra scopes -->

### Cloning iterators

So, you have an iterator, and you want to clone all the things in the
iterator so that you can operate on owned rather than borrowed values.
Maybe you've written code like

```rust
for element in elements.iter() {
    let element = element.clone();
    // do something with element
}
```

or

```rust
elements.iter().map(|e| e.clone()) // .who_knows
```

There's a better way! Among [all the cool
things](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
that iterator gives you, there is
[`.cloned`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.cloned),
which does exactly this for you. Use

```rust
for element in elements.iter().cloned() {
// or 
elements.iter().cloned()
```

### Give me the index, please

You iterate a lot in Rust. And every now and again, it is useful to know
*where* in the iterator you are. There are *many* ways to do this. If
you have a list or vector, you may be tempted to emulate a good-ol'
"counter style" for loop:

```rust
for i in (0..list.len()) {
    let e = &list[i];
    // do something with i and e
}
```

Or if you can't index into `list` directly, you might reach for the good
old counter variable trick:

```rust
let mut i = 0;
for e in list.iter() {
    // do something with i and e
    i += 1;
}
```

These both do what you expect, but they aren't particularly "Rust-y".
Say hello to
[`.enumerate()`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.enumerate)

```rust
for (i, e) in list.iter().enumerate() {
    // do something with i and e
}
```

### Partial matching

A very powerful feature that Rust shares with many other functional
programming languages is pattern matching. This is found in many places
in the language, but its primary application can be found in `match`. It
turns out that `match` has a few tricks up its sleeves that may not be
obvious to newcomers to the language.

Let's say you have some function, `foo`, which returns an `enum` of some
sort that you wish to modify before returning it. You may be tempted to
write code like this

```rust
let mut v = foo();
match v {
    Enum::Bar(ref mut x) => {
        x += 1;
    },
    Enum::Baz(ref mut y) => {
        y -= 1;
    },
    _ => (), // needed to make pattern exhaustive
};
v
```

But `match` can make this much nicer:

```rust
match foo() {
    Enum::Bar(x) => Enum::Bar(x + 1),
    Enum::Baz(x) => Enum::Baz(x - 1),
    v => v,
}
```

Notice that the last pattern is a catch-all, which simply returns
anything not captured by the previous patterns as-is. We've also gotten
rid of the `v` variable entirely. Pretty neat!

`match` can also do things like convert all non-`Bar`s into `Bar`s by
binding a variable to an entire pattern:

```rust
match foo() {
    f@Enum::Bar(_) => f,
    _ => Enum::Bar(0),
}
```

You can find a number of other cool `match` tricks in [The
Book](https://doc.rust-lang.org/book/patterns.html).

### Avoid warnings for unused variables

You're implementing a method for a trait, but you don't need all the
variables:

```rust
trait Foo { fn hello(x: &str, y: bool) }

struct Bar
impl Foo for Bar {
    fn hello(x: &str, y: bool) {
        println!("{}", x);
    }
    // WARNING: unused variable `y`
}
```

You can get around this in a couple of ways.
The idiomatic way is to replace those variables with `_`, which
signifies *do not bind this value*:

```rust
impl Foo for Bar {
    fn hello(x: &str, _: bool) { // ...
```

You can also assign the unused variable to `_` inside the function body
(this is less idiomatic, but works in more places):

```rust
impl Foo for Bar {
    fn hello(x: &str, y: bool) {
        let _ = y;
        // ...
```


The first version above is *usually* what you want. However, assigning
to `_` actually [immediately drops the
value](https://github.com/rust-lang/rust/issues/10488). If this is not
what you want, you can instead silence the warning for the function in
question. However, bear in mind this will also silence the warning for
any other unused variables in the function's body.

```rust
impl Foo {
    #[allow(unused_variables)]
    fn hello(x: &str, y: bool) { // ...
```

### Enforcing documentation

Did you know that you can make the Rust compiler yell at you if you've
forgotten to write documentation for *any* part of your code that is
visible to outside users? Just add the following magical line to your
crate entry point (probably `src/lib.rs`):

```rust
#![deny(missing_docs)]
```

### Other things?

If you know of other tricks that should go in this post, feel free to
get in touch, or send a [GitHub
PR](https://github.com/jonhoo/thesquareplanet.com/pulls), and I'll be
happy to take a look.
