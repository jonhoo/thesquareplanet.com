---
layout: post
title: Instructors' Guide to Raft
date: '2016-03-06 16:17:10'
---

For the past few months, I have been a Teaching Assistant for MIT's
[6.824 Distributed Systems](https://pdos.csail.mit.edu/6.824/) class.
The class has traditionally had a number of labs building on the Paxos
consensus algorithm, but this year, we decided to make the move to
[Raft](https://raft.github.io/). Raft was "designed to be easy to
understand", and our hope was that the change might make the students'
lives easier.

This post, and the accompanying [Students' Guide to Raft](post_url students-guide-to-raft) post, chronicles our journey with Raft, and
will hopefully be useful to implementers of the Raft protocol, teachers
looking to add Raft to their curriculum, and students trying to get a
better understanding of Raft's internals. This post is aimed mainly at
Raft from an educational perspective, and might be useful to you if you
are considering using Raft in your class.  If you want to *build* or
*understand* Raft, you should look at the Students' Guide linked to
above.

Before we dive into Raft, some context may be useful. 6.824 used to have
a set of [Paxos-based
labs](http://nil.csail.mit.edu/6.824/2015/labs/lab-3.html) that were
built in [Go](https://golang.org/); Go was chosen both because it is
easy to learn for students, and because is pretty well-suited for
writing concurrent, distributed applications (goroutines come in
particularly handy). Over the course of four labs, students build a
fault-tolerant, sharded key-value store. The first lab has them build a
consensus-based log library, the second adds a key value store on top of
that, and the third shards the key space among multiple fault-tolerant
clusters, with a fault-tolerant shard master handling configuration
changes. We also had a fourth lab in which the students had to handle
the failure and recovery of machines, both with and without their disks
intact. This lab was available as a default final project for students.

This year, we decided to rewrite all these labs in Raft. The first three
labs were all the same, but the fourth lab was dropped as persistence
and failure recovery is already built into Raft. This article will
mainly discuss our experiences with the first lab, as it is the one most
directly related to Raft, although I will also touch on building
applications on top of Raft (as in the second lab).

### Explaining Raft

The Raft protocol is, as it purports to be, a fairly straightforward
algorithm to explain at a high level. Visualizations like [this
one](http://thesecretlivesofdata.com/raft/) give a good overview of the
principal components of the protocol, and the paper gives good intuition
for why the various pieces are needed. If you haven't already read the
[extended Raft paper](http://ramcloud.stanford.edu/raft.pdf), you should
go read that before continuing this article, as I will assume a decent
familiarity with Raft.

As with all distributed consensus protocols, the devil is very much in
the details. In the steady state where there are no failures, Raft's
behavior is easy to understand, and can be explained in an intuitive
manner. For example, it is simple to see from the visualizations that,
assuming no failures, a leader will eventually be elected, and
eventually all operations sent to the leader will be applied by the
followers in the right order.

However, when delayed messages, network partitions, and failed servers
are introduced, some fairly sophisticated reasoning about the exact
rules dictated by the specification (the paper) is required to explain
why Raft behaves correctly. Since our automated grading tool for the lab
is rigorous, adversarial, and quite abusive, students will generally be
exposed to many combinations of the aforementioned failures. They are
forced to really dig into their implementations to find places where
they don't follow the directions of the paper to the letter.

The ultimate guide to Raft is in Figure 2 of the Raft paper. This figure
specifies the behavior of every RPC exchanged between Raft servers, and
also gives various invariant that servers should maintain, and when
certain actions should occur. Both your teaching, the students
attention, and the rest of this article will be centered around Figure
2. When students give example executions and ask how Raft prevents them,
it often takes a considerable amount to backtrack through the protocol
(and the rules from Figure 2), and decide exactly what message would
cause the situation not to occur. This problem is not unique to Raft,
and is one that all complex distributed systems that provide correctness
must tackle.

### Raft and Paxos

Paxos is a somewhat different beast to Raft. It is also a somewhat
ambiguous term, so let's get some terminology out of the way. Paxos is
really two things: an algorithm for single-value consensus, and a
protocol for state machine replication. In the rest of this post, I will
be referring to the former as Paxos, and the latter as Paxos RSM.

Where Raft provides a full protocol for building a distributed,
consistent log, Paxos at its core only offers a solution for
single-value agreement. Because of this, Paxos is also conceptually
simpler than Raft is -- implementing and understanding Paxos correctly
is not all that hard, as long as all you care about is single value
agreement. It's when you need to agree one a *sequence* of
operations that Paxos (at that point, Paxos RSM) becomes complicated.

Some papers have been published on how to do this in an efficient
manner, but the general idea is that you run multiple instances of
Paxos, where the messages for each instance is "tagged" with the index
of that value in the global log.  Since each instance of Paxos will
agree on only one value, this scheme ensures that eventually all peers
agree on one value for each index, which you can use to construct a log.

To build Paxos RSM with similar features as Raft, you really have to
build three components: first, a Paxos agreement "thing" that implements
consensus for a single value in the log. Second, a "thing" that checks
whether there exists some `i` such that all the Paxos instances for
every index less than `i` have reached agreement, and if so, applies
those values in order. And third, a "thing" that takes a new value to be
added to the log, keeps trying to stick it into some index in the log
(probably one past the end of the current log), and returns when the new
value was agreed upon for some index. In Raft, these features are all
integrated in a single package.

### Implementing Raft

As previously mentioned, the go-to guide for implementing Raft is Figure
2 of the extended Raft paper. It defines what every server should do, in
ever state, for every incoming RPC, as well as when certain other things
should happen (such as when it is safe to apply an entry in the log). At
first, both you and the students might be tempted to treat Figure 2 as
sort of an informal guide; you read it once, and then start coding up an
implementation that follows roughly what it says to do. Doing this, you
will quickly get up and running with a mostly working Raft
implementation. And then the problems start.

Figure 2 is, in fact, extremely precise, and every single statement
it makes should be treated, in specification terms, as **MUST**, not as
**SHOULD**. For example, one might reasonably reset a peer's election
timer whenever you receive an `AppendEntries` or `RequestVote` RPC, as
both indicate that some other peer either thinks it's the leader, or is
trying to become the leader. Intuitively, this means that we shouldn't
be interfering. However, if you read Figure 2 carefully, it says:

> If election timeout elapses without receiving `AppendEntries` RPC
> *from current leader* or *granting* vote to candidate: convert to
> candidate.

The distinction turns out to matter a lot, as the former implementation
can result in significantly reduced liveness in certain situations.

This is not, in and of itself, a problem. It is to be expected that a
consensus algorithm specification is precise, and that if you don't
follow it exactly, things break. Unfortunately, Raft's conceptual
simplicity becomes its undoing here. Students quickly feel as though
they understand Raft well enough, and so they glance over Figure 2, and
write an implementation that does what they think it should. In some
cases, the "intuitive" behavior is correct, but Raft is also littered
with cases where the exact wording of Figure 2 turns out to be extremely
important, and to differ subtly from the "obvious" solution. You should
have a look at the Students' Guide for details on this.

You might argue that the students had no reason to take these
"shortcuts" in the first place. And technically, you would be right.
They should have followed Figure 2 to the letter, and they wouldn't have
this problem. Unfortunately, they don't. This could be because they are
not used to following formal specifications, because Figure 2 doesn't
*look* like a formal specification, or because it's easy to miss some of
these subtle points, but it doesn't really matter. What matters is that
students (and most other programmers) *will* miss subtleties in the
specification. And Raft has a lot of them. That's not a great
combination.

### Did Paxos fare better?

Judging from the feedback from our students, the first Raft lab was
considerably more work than the equivalent Paxos RSM lab from last year.
Students reported that while Raft was fairly easy to *understand*,
actually *implementing* it in the lab, and getting all the corner cases
correct, was both hard and extremely time-consuming. Admittedly, there
are some differences, namely that the Raft implementation also adds
sticky leader and persistence, but we do not believe those features
contribute particularly to Raft's implementation complexity.

We originally switched to Raft because we believed that it would be
easier for the students to follow a complete design, than fiddling with
how to construct Paxos RSM out of Paxos' single-value agreement. Since
there aren't any particularly good, complete descriptions of how to
build Paxos RSM, students had to cook up a scheme themselves, which is
an error-prone process.

Although Raft does give an end-to-end algorithm, and a very thorough
description of it, I think what has made it harder for students to
implement, is that Raft is tricky to build in a piece-wise fashion. It
is almost an all-or-nothing affair; either you follow every rule in the
paper to the letter, or you missed one somewhere and your entire
implementation is broken (and often in subtle and hard-to-debug ways).
The net result of this is that students ended up spending more time
debugging this lab than they did the Paxos RSM lab, simply because at some
point they knew one "part" of their solution was correct (like Paxos
single-value agreement), and so could ignore that while debugging.

A natural question to ask then is: is Raft still "better" or "easier"
than Paxos (and Paxos RSM) from an educational point of view? While
distributed consensus is inherently complicated, the Raft authors have
tried very hard to make a protocol that is easily digestible and
understandable, at least in the general case. And they have succeeded in
doing so. Students reported that they felt as though they understood
Raft well, and that the design was easy to follow, including how the
different pieces fit together. However, in the 6.824 lab, and when
writing distributed systems in "the real world", you are forced to
tackle all the many nasty corner cases, and that requires thinking very
carefully about the tiniest details in the underlying algorithm.

Raft may be straightforward in the general case, but when you have to
reason about what happens when you have a healing a minority partition
with an old leader and a majority partition with a new leader, things
are bound to get tricky. No matter how "simple" the algorithm is,
reasoning about why it's correct in all these cases (and correctly
implementing all the vital components) is hard. What helps Paxos-based
designs here is that they are *layered*. For any given bug, you can
usually decide whether the bug is in your single-value agreement (i.e.,
Paxos), or in your log construction, which reduces the cognitive load of
debugging. In fact, you test these components separately, so that you
can home in on where your bugs are much faster than if everything is
integrated in a single protocol.

That all said, one might argue that the Raft approach here is much
safer, and what we should be teaching students -- when students come up
with their own distributed algorithms, it is quite hard to determine
whether they are *always* correct. Exposing them to a well
though-through, end-to-end algorithm like Raft teaches them about all
the things you need to consider if you really want correct behavior in
every case. And maybe the added implementation complexity is the price
we have to pay for that.

Despite the increased perceived difficulty of our labs after switching
to Raft, we are going to continue using Raft for 6.824 labs in the
coming years. This is for two main reasons. First, we feel as though it
is important that students are exposed to mature, complete, and correct
distributed algorithms; while having them come up with their own scheme
for building Paxos RSM is certainly an interesting intellectual
challenge, it is not clear that it makes them "better" at distributed
systems. Second, it is arguably more important that the students feel as
though they understand the workings of the algorithm, than to test
whether they can quickly and correctly translate the textual description
of an algorithm into bug-free code.

In an attempt to improve the situation for future years, and to help
other students of Raft (academic or otherwise), we have also written the
[Students' Guide to Raft](post_url students-guide-to-raft). It
gives a more implementation-oriented description of the Raft protocol,
discusses common questions and pitfalls, and gives(/will eventually
give) pseudocode for a correct implementation. You may find it an
interesting read.
