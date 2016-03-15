---
layout: post
title: Instructors' Guide to Raft
date: '2016-03-06 16:17:10'
---

For the past few months, I have been a Teaching Assistant for MIT's
[6.824 Distributed Systems](https://pdos.csail.mit.edu/6.824/) class.
The class has traditionally had a number of labs building on the Paxos
consensus algorithm, but this year, we decided to make the move to
[Raft](https://raft.github.io/). Raft was designed to be easy to
understand, and our hope was that the change might make the students'
lives easier.

This post, and the accompanying [Students' Guide to Raft](post_url
students-guide-to-raft) post, chronicles our journey with Raft, and will
hopefully be useful to teachers looking to add Raft to their curriculum.
This post is aimed mainly at Raft from an educational perspective, and
might be useful to you if you are considering using Raft in your class.
If you want to *build* or *understand* Raft, you should look at the
Students' Guide linked to above instead.

Before we dive into Raft, some context may be useful. 6.824 used to have
a set of [Paxos-based
labs](http://nil.csail.mit.edu/6.824/2015/labs/lab-3.html) that were
built in [Go](https://golang.org/); Go was chosen both because it is
easy to learn for students, and because is pretty well-suited for
writing concurrent, distributed applications (goroutines come in
particularly handy). Over the course of several labs, students build a
fault-tolerant, sharded key-value store. The first lab had them build a
consensus-based log library, the second added a key value store on top of
that, and the third sharded the key space among multiple fault-tolerant
clusters, with a fault-tolerant shard master handling configuration
changes. This article will discuss our experiences with rewriting the
first lab, as it is the one most directly related to Raft.

### Explaining Raft

The Raft protocol is, as it purports to be, a fairly straightforward
algorithm to explain at a high level. Visualizations like [this
one](http://thesecretlivesofdata.com/raft/) give a good overview of the
principal components of the protocol, and the paper gives good intuition
for why the various pieces are needed. If you haven't already read the
[extended Raft paper](http://ramcloud.stanford.edu/raft.pdf), you should
go read that before continuing this article, as I will assume a decent
familiarity with Raft.

In the steady state where there are no failures, Raft's behavior is easy
to understand, and can be explained in an intuitive manner. For example,
it is simple to see from the visualizations that, assuming no failures,
a leader will eventually be elected, and eventually all operations sent
to the leader will be applied by the followers in the right order.

As with all distributed consensus protocols, the devil is very much in
the details. When networks delay RPCs, networks are partitioned, and
servers fail, some fairly sophisticated reasoning about the exact rules
dictated by the specification (the paper) is required to explain why
Raft behaves correctly. The ultimate guide to Raft is in Figure 2 of the
Raft paper, which specifies the behavior of every RPC exchanged between
Raft servers, gives invariants that servers should maintain, and dictate
when certain actions should occur. Both your teaching, the students
attention, and the rest of this article will be centered around Figure
2.

### Raft and Paxos

An important difference between our Paxos and Raft labs is that our
Paxos labs were based on Paxos, the single-value consensus algorithm,
not Multi-Paxos, which adds features such a single-round soft leader
commits. The latter is quite often also referred to simply as Paxos.

The general idea when building a replicate state machine on top of Paxos
is that you run multiple instances of Paxos consensus, where the
messages for each instance is "tagged" with the index of that value in
the global log. Multi-Paxos adds a number of optimizations on top of
this, which adds a fair amount of complexity. For 6.824, we decided the
increased performance was not worth the added complexity for the
purposes of teaching. Instead, we had the students design their own
simple protocol for keeping a replicated log on top of Paxos, and from
that, a replicate state machine.

Raft, in contrast to Paxos, provides a full protocol for building a
distributed, consistent log, including a number of optimizations such as
leader election, single-round agreement, and snapshotting. Raft is thus
much more similar to Multi-Paxos, both in terms of feature set,
performance, and complexity, than to Paxos. Paxos consensus alone (i.e.,
not Multi-Paxos) is conceptually much simpler than Raft.

### Implementing Raft

The go-to guide for implementing Raft is Figure 2 of the extended Raft
paper. At first, both you and the students might be tempted to treat
Figure 2 as sort of an informal guide; you read it once, and then start
coding up an implementation that follows roughly what it says to do.
Doing this, you will quickly get up and running with a mostly working
Raft implementation. However, Figure 2 is, in reality, much closer to a
formal specification, where every clause is a **MUST**, not a
**SHOULD**. The Students' Guide to Raft goes into a great deal of depth
about this. Failure to follow Figure 2 *to the letter* very often leads
to complex bugs, and errors in one part of the algorithm (e.g.,
snapshotting) can often adversely impact seemingly unrelated parts of
the protocol (e.g., leader election).

This is not, in and of itself, a problem. It is to be expected that a
consensus algorithm specification is precise, and that if you don't
follow it exactly, things break. However, the fact that Raft bakes in a
number of optimizations into the consensus algorithm, means that there
are many more things that can go wrong than for a "simple" RSM
implementation on top of Paxos.

If you want to assign a stripped-down, low-performance RSM to students
to teach them the basics of consensus-based distributed systems, we know
how to do that starting with Paxos. If you forego the optimizations
implemented by Multi-Paxos, and instead use simple multi-round Paxos
agreement for each value in the log, you get a design that seems to us
to be simpler than both Raft and current practice for Paxos-derived RSM.
We don't know how to do that starting with Raft, in part because Raft
has a fair amount of sophistication and optimization melded into its
core protocol.

### Did Paxos fare better?

We originally switched to Raft because we believed that it would be
easier for the students to follow a complete design, than fiddling with
how to construct their own Paxos RSM protocol out of Paxos' single-value
agreement. However, judging from the feedback from our students, the
first Raft lab was considerably more work than the equivalent Paxos RSM
lab from last year. Students reported that while Raft was fairly easy to
*understand*, actually *implementing* it in the lab, and getting all the
corner cases correct, was both hard and extremely time-consuming.

A natural question to ask then is: is Raft still "better" than Paxos
(and Paxos RSM) from an educational point of view? Distributed consensus
is undoubtedly a complicated affair, and the Raft authors have tried
very hard to make a protocol that is easily digestible and
understandable, at least in the general case. And they have succeeded in
doing so. Students reported that they felt as though they understood
Raft well, and that the design was easy to follow, including how the
different pieces fit together.

One might argue that the stripped-down Paxos RSM approach we took with
the previous set of labs were overly simplistic. That exposing them
to a well though-through, end-to-end algorithm like Raft or Multi-Paxos
teaches them about all the things you need to consider if you really
want correct behavior in every case, and that that is the "right" thing
to teach them in a class on distributed systems. And maybe the added
implementation complexity is the price we have to pay for that.

### Going forward

Despite the increased perceived difficulty of our labs after switching
to Raft, we are going to continue using Raft for 6.824 labs in the
coming years. This is for two main reasons. First, we feel as though it
is important that students are exposed to mature, complete, and correct
distributed algorithms; while having them come up with their own scheme
for building Paxos RSM is certainly an interesting intellectual
challenge, it is not clear that it makes them "better" at building
distributed systems. Second, it is arguably more important that the
students feel as though they understand the workings of the algorithm,
than to test whether they can quickly and correctly translate the
textual description of an algorithm into bug-free code.

In an attempt to improve the situation for future years, and to help
other students of Raft (academic or otherwise), we have also written the
[Students' Guide to Raft](post_url students-guide-to-raft). It
gives a more implementation-oriented description of the Raft protocol,
discusses common questions and pitfalls, and gives(/will eventually
give) pseudocode for a correct implementation.
