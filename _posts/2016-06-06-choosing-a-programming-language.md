---
layout: post
title: Choosing a Programming Language
date: '2016-06-06 16:48:42'
shared:
  Hacker News: https://news.ycombinator.com/item?id=11850257
  Twitter: https://twitter.com/Jonhoo/status/739922998019248129
  Reddit: https://www.reddit.com/r/programming/comments/4mv7ob/choosing_a_programming_language/
---

One of the first decisions one has to make when learning to program is
which programming language to learn. In many cases, the choice is made
for you, dictated either by the language used in a particular class, or
by a particular function you would like to perform, but often you will
have at least a few options.

Picking your first (and second) language can be daunting, as there are
so many candidates out there, and it's not always clear how they differ,
and which are "better". This post will try to give a high-level overview
of the choices that are available, and what differentiates them, to aid
you in making an informed decision. It is not a "review" of any of these
languages, nor does it aim to find the "best" programming language out
there.

## Choosing a language

Programming languages generally belong to a number of different
categories. These are often referred to as "paradigms" in the
literature. As we'll see shortly, the lines between different paradigms
are often blurred, especially when it comes to more modern languages.
Nevertheless, they can be useful for limiting the number of languages to
look at in more detail.

Through all of this, it is important to keep in mind that these
languages *can all do the same things* --- they all let you print to the
screen, do math, read files, connect to the internet, etc. They differ
in *how* they enable you to do that, and in many cases, how *convenient*
it is to do those things. Some languages are more suitable for doing
statistical computation, some are better for building websites, and
others are better for interacting with hardware. This is part of the
reason why it's important to ask yourself what *kind* of thing you want
to do first, and only then start looking for a language.

### Level of abstraction

Let's start with one of the most discriminatory features of programming
languages: the level of abstraction from the hardware. Languages that
hide more of the inner workings of the computer from the programmer are
usually referred to as "high-level", whereas those that expose these
low-level details are called "low-level". This distinction is more of a
scale than it is a categorization --- plenty of languages can be
considered "mid-level" in terms of abstraction.

In general, abstractions come at a price, and the higher level the
languages, the lower the performance. That said, even high-level
languages have performance that is suitable for *most* applications. You
should find a language in the "highest" category whose performance your
application can tolerate.

Increased abstraction also hides more of the inner workings of your
program from you --- there's more "magic" going on behind the scenes.
This is often what you want, as it can save you a lot of typing, but it
may cause frustration if things break or underperform, and you have to
figure out why. How much magic is right for you is a matter of personal
taste, and you may have to play around with multiple languages before
you find what's right for you.

Without further ado, let's look at a few different "tiers" on this
scale, and examples of what languages fit in each tier.

- **Little to no abstraction.** At the bottom of the scale, we have
  a set of languages that are commonly referred to as *assembly code*.
  Assembly is an almost direct mapping of the machine instructions
  understood by your CPU, and thus there exist many different variants of
  assembly, each one mapping to a different type of CPU. Every statement
  in your code is a single machine operation, such as "store this value
  to this piece of memory" or "add the values from these two pieces of
  memory".
  
  This kind of code is usually only used for code that needs to interact
  with devices on a very low-level (e.g. the operating system kernel),
  or that needs to squeeze every last bit of performance out of the
  hardware at hand (e.g. video decoding). It is unlikely that you will
  want to choose an assembly languages as your first language.

- **Machine-independence.** A bit further up, we find C (and notably not
  its cousin C++). These languages are still fairly low-level; their
  code maps very closely to the operations the hardware can perform, and
  they require you to manage your own memory ("I'd like 2 MB of memory,
  please"; "I'm done with it now, thanks"). However, they also provide
  abstractions such as *functions* (pieces of code that can be reused),
  *loops* (code that is executed several times), and *types*
  (annotations on memory saying that it contains, say, a number instead
  of a letter).
  
  Languages in this category are usually *compiled*, meaning that the
  code you write must be passed through a "compiler" --- a program that
  translates your program to code the hardware can understand --- before
  you can run it. This allows C to be *machine-independent*. The code
  you write can be written once, and then compiled to different types of
  hardware.

  C-like languages are popular because they generally perform well
  (because the code maps so closely to the hardware), and because they
  are conceptually quite simple (there's very little magic --- the code
  you write is what's run). The downside to these languages is that you
  often need to write a lot of code, precisely because you have to spell
  out every step of the program. You should consider these languages if
  performance if your primary concern.

- **Mid-level languages.** In this next category, we find the languages
  that still target high performance, but that aim to also provide some
  additional abstraction from the low-level workings of the hardware.
  These abstractions can take a variety of forms, but common examples
  are *closures* (roughly speaking, a function that is constructed when
  the program is run), *semi-automatic memory management*, and
  *generics* (functions that can operate on data of different types; for
  example, a dictionary that can use either strings or numbers are
  keywords). These often allow you to express your code in a more
  concise way, and offloads some of the tedious step-by-step enumeration
  to the compiler. Examples of well-known languages in this category are
  C++, C#, and Rust.

- **Languages with runtimes.** Languages in this tier also include a
  *runtime* --- when your program is running, some other code that's
  part of the language is running alongside it, performing features such
  as *garbage collection* (automatically figuring out when memory is no
  longer needed) and *greenthreading* (more efficiently running more
  concurrent computations than there are processors on the machine).
  These features usually come with some performance penalty (though you
  probably won't notice unless you're writing very performance-sensitive
  applications), but can make programming both simpler and safer.
  
  The runtime does, in many cases, make it harder to write programs that
  interact with other languages. For example, high-performance
  implementations of complex mathematical operations such as large
  matrix multiplications are often implemented in FORTRAN or C, and it
  can be difficult to take advantage of those kinds of libraries when
  you are in a language with a runtime. Popular languages in this
  category are Java, Scala, Go, and Swift.

- **Interpreted languages.** Programs written using languages in this
  tier are generally much slower than those in the categories above, but
  are often much easier to write. The biggest advantage of code written
  in interpreted languages is that it can be *partially executed*. You
  can write a piece of code, run it, write some more code, and then run
  that new code as if it followed the code that you ran previously. This
  is useful for quickly constructing one-off computations
  piece-by-piece, as well as for figuring out where something goes wrong
  in your program (you can inspect the state of your program as it's
  running).
  
  Interpreted languages are also often much more lenient about what your
  code can do; they often allow *monkey-patching* (changing the behavior
  of a running program), *code evaluation* (executing code that you read
  from a file or over the network during as part of running your
  program), and *type conversion* (a string containing a number can
  simply be used as a number directly). However, this lenience
  introduces new classes of bugs that can be hard to find and fix, since
  what code actually ended up running is not immediately obvious. For
  this reason, complex, long-running software is usually written in a
  compiled language, whereas interpreted languages are used for writing
  management tools, data analytics, one-off scripts, and websites.
  Website development is an example where the ability to rapidly iterate
  on the code is particularly important, which the run-as-you-go
  approach of interpreted languages fits nicely.

  There are *a lot* of interpreted languages out there. The most popular
  ones are Python, PHP, JavaScript, Perl, Ruby, and Lua.

- **Specialized languages.** These are languages that have been built to
  cater for particular use-cases. It is often difficult to say what
  level of abstraction they provide, because they are usually very
  high-level for the target use, but provide very low-level primitives
  if you want to do something non-standard. In general, you will only
  want to use these languages if you are trying to do exactly what they
  are built for. Common examples here are R (for statistical
  computations), MATLAB (for math-heavy computations), SQL (for database
  querying), and Prolog (for logic-based inference). We will not be
  talking a lot about specialized languages, since you generally know if
  you should be using them.

- **High-level languages.** These languages often depart significantly
  from the computational model used by the languages we have discussed
  thus far. They make little or no effort to conform to the way the
  hardware executes code (one small computation or memory operation at
  the time), and instead let you focus on the high-level properties of
  your algorithm. In many ways, these languages are more like executable
  math formulas than they are machine code. As a result, programs
  written in these languages often have fewer bugs, and are more likely
  to work correctly if the compiler accepts the code.

  Languages at this level of abstraction can be, and have been, used to
  build "traditional" programs. However, where they really shine is when
  they are used to parse and reason about the behavior of other
  programs, or formally verify properties and invariants of the code
  itself. For example, in these languages it is often possible to
  *prove* that the program will never fail in a particular way, or that
  a performance optimization always returns the same answer as the
  slower, naïve implementation.

  You'll want to use these languages if performance is not of critical
  performance to you, or if you want strong guarantees about the
  correctness of your code. Be aware that they can be somewhat tedious
  to get started with, since it can be hard to convince the compiler
  that your code is in fact correct. Well-known languages in this tier
  are Haskell, F#, Coq, LISP, and OCaml.

### Strictness

Finding the right level of abstraction usually takes you a long way
towards picking a language. This is particularly true as many of the
languages within each tier are fairly similar in terms of features, and
mostly vary in syntax. Nonetheless, it can be useful to have a second
scale on which to evaluate different languages within a tier. I have
often found it useful to compare languages in terms of their
"strictness". Stricter languages are harder to write code for, as they
require you to convince the compiler that your code adheres to some
notion of "correct", but once your code compiles, you can be more
certain that it does the right thing. Conversely, less strict languages
place fewer restrictions on your code, but your programs are more likely
to break when you run them.

So, in order from less to more strict:

- **Do whatever you want.** These languages let you get away with pretty
  much anything. Want to add the letter `S` to the value `true`? Sure,
  go ahead! Want to make `+` ignore its arguments and always return "One
  ring to rule them all" instead? That's fine. This flexibility allows
  you to do really neat things, like modifying and evaluating your
  program as it's running. It also means your code will do *something*
  the first time you run it. If you know what you're doing, or if you're
  doing something simple where retrying if it's wrong isn't too costly,
  this is great. If this run-crash-fix-re-run loop sounds frustrating
  though, you may want to look for a different kind of language.

  Languages in this category are JavaScript, PHP, Perl, Ruby, and
  arguably LISP. There are also languages that are slightly more strict,
  and will check that you haven't done something completely crazy, but
  that still belong to this general category. Python and TypeScript are
  examples of such languages. These languages are sometimes referred to
  as *dynamically typed*.

- **Try to make sense.** These languages require that your code behaves
  rationally. If `+` is a function that takes two number and returns a
  number, you can't just go ahead and return `true` instead. This gets
  rid of a lot of bugs related to incorrect types at runtime, but also
  means that it's harder to, for example, convert user input from a
  string to a number. These languages still have shortcuts you can take
  to circumvent many of the checks (see `interface{}` in Go, `void*` in
  C, and `Object` in Java), but in general force you to write sensible
  code. Examples of these languages are Go, C, C++, and Java. These are
  often referred to as *statically typed*.

- **No cheating.** Now we're getting into the land of "no shenanigans".
  Not only do you have to convince the compiler that your program
  doesn't do something silly like mixing numbers and strings, you *also*
  have to ensure that it doesn't do anything *dangerous*. This can be
  that your program isn't allowed to modify immutable data, have data
  that is concurrently modified, or to read data after it has been
  wiped. There are many different approaches to this, such as
  disallowing mutable data altogether (Haskell), or checking these
  properties at compile time (Rust). Other languages in this category
  are Erlang, Prolog, and F#.

- **Show me proof.** In these languages, it is no longer sufficient to
  show that your program isn't wrong. You have to show that it in fact
  does the right thing. This usually involves writing a proof that the
  code you've written changes the state of the world in some way, or
  that there doesn't exist an input that causes your program to do
  something incorrect. I don't have much experience with these
  languages, but they have seen a surge of popularity over the past few
  years, with people trying to formally verify the behavior of
  increasingly complex applications. Languages such as Coq, Agda, Dafny,
  Isabelle, and `F*`.

## Switching languages

The descriptions I've given above will hopefully help you make a good
decision about what language to dive into. Inevitably, however, you will
find that the language you picked doesn't work very well for some
particular task, or that there's something that irks you about it. When
this happens, don't be afraid to try out another language! In many
cases, you will find that the new language differs from your current one
mostly in terms of syntax, especially if you are switching between
languages of a similar level of strictness and abstraction.

Switching to languages that are "farther apart" is harder, as there are
new concepts you need to learn. Luckily, much of your existing
experience will translate easily --- notions like variables, strings,
functions, modules are found in almost all languages. Furthermore, the
more languages you know, the easier it is to learn new ones. This is one
of the reason experienced developers often claim that they know dozens
of languages; each additional language becomes easier to learn. In many
cases, learning a new language can even change the way you program in
the languages you already know! Picking up another language, or sampling
a bunch of them, is a natural part of developing yourself as a
programmer --- don't be afraid to try!

Good luck, and don't be too stressed about the decision. Especially in
the beginning, everything you learn will come to good use, even if you
later change your mind.
