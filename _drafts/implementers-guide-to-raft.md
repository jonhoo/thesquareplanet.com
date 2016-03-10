---
layout: post
title: Implementers' Guide to Raft
date: '2016-03-06 16:17:10'
---

For the past few months, I have been a Teaching Assistant for MIT's
[6.824 Distributed Systems](https://pdos.csail.mit.edu/6.824/) class.
The class has traditionally had a number of labs building on the Paxos
consensus algorithm, but this year, we decided to make the move to
[Raft](https://raft.github.io/). Raft was "designed to be easy to
understand", and our hope was that the change might make the students'
lives easier.

This post chronicles our journey with Raft, and will hopefully be useful
to implementers of the Raft protocol, teachers looking to add Raft to
their curriculum, and students trying to get a better understanding of
Raft's internals. If you are looking for a Paxos vs Raft comparison, you
may find the content somewhat lacking, though I will touch on the
subject wherever it is relevant.

Before we dive into Raft, some context may be useful. Feel free to skip
this if you already have an implementation in mind and you don't care
particularly about 6.824. The old [Paxos-based
labs](http://nil.csail.mit.edu/6.824/2015/labs/lab-3.html), as well as
the new Raft labs, are all built in [Go](https://golang.org/); Go was
chosen both because it is easy to learn for students, and because is
pretty well-suited for writing concurrent, distributed applications
(goroutines come in particularly handy). Over the course of three (Raft)
or four (Paxos) labs, students build a fault-tolerant, sharded key-value
store. The first lab has them build a consensus-based log library, the
second adds a key value store on top of that, and the third shards the
key space among multiple fault-tolerant clusters, with a fault-tolerant
shard master handling configuration changes. For Paxos, we also had a
lab where the students had to handle the failure and recovery of
machines, both with and without their disks intact; this was not
relevant for Raft, as the Raft protocol already has persistence
built-in. This article will focus mainly on the first lab, as it is the
one most directly related to Raft, although I will also touch on
building applications on top of Raft (as in the second lab).

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
rules dictated by the spec (the paper) is required to explain why Raft
behaves correctly. When students give example executions and ask how
Raft prevents them, it often takes a considerable amount to backtrack
through the protocol and decide exactly what message would cause the
situation not to occur. This problem is not unique to Raft, and is one
that all complex distributed systems that provide correctness must
tackle.

The ultimate guide to Raft is in Figure 2 of the Raft paper. This figure
specifies the behavior of every RPC exchanged between Raft servers, and
also gives various invariant that servers should maintain, and when
certain actions should occur. We will be talking about Figure 2 *a lot*
in the rest of this article. Since our automated grading tool for the
lab is rigorous, adversarial, and quite abusive, students will generally
be exposed to many combinations of the aforementioned failures. They are
forced to really dig into their implementations to find places where
they don't follow Figure 2 to the letter.

### Raft and Paxos

Paxos is a somewhat different beast to Raft; where Raft provides a full
protocol for building a distributed, consistent log, Paxos only offers a
solution for single-value agreement. Because of this, Paxos is also
conceptually simpler than Raft is -- implementing and understanding
Paxos correctly is not all that hard, as long as all you care about is
single value agreement. It's when you need to agree one a *sequence* of
operations that Paxos becomes complicated. Some papers have been
published on how to do this in an efficient manner, but the general idea
is that you run multiple instances of Paxos, where the messages for each
instance is "tagged" with the index of that value in the global log.
Since each instance of Paxos will agree on only one value, this scheme
ensures that eventually all peers agree on one value for each index,
which you can use to construct a log.

To build something with similar features as Raft using Paxos, you really
have to build three components: first, a Paxos agreement "thing" that
simply implements Paxos for a single value. Second, a "thing" that
checks whether there exists some `i` such that all the Paxos instances
for every index less than `i` have reached agreement, and if so, applies
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
first, one might be tempted to treat Figure 2 as sort of an informal
guide; you read it once, and then start coding up an implementation that
follows roughly what it says to do. Doing this, you will quickly get up
and running with a mostly working Raft implementation. And then the
problems start.

Figure 2 is, in fact, extremely precise, and every single statement
it makes should be treated, in specification terms, as **MUST**, not as
**SHOULD**. For example, one might reasonably reset a peer's election
timer whenever you receive an AppendEntries or RequestVote RPC, as both
indicate that some other peer either thinks it's the leader, or is
trying to become the leader. Intuitively, this means that we shouldn't
be interfering. However, if you read Figure 2 carefully, it says:

> If election timeout elapses without receiving AppendEntries RPC *from
> current leader* or *granting* vote to candidate: convert to candidate.

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
important, and to differ subtly from the "obvious" solution.

#### The importance of details

To make the discussion more concrete, let us consider an example that
tripped up a number of 6.824 students. The Raft paper mentions
*heartbeat RPCs* in a number of places. Specifically, a leader will
occasionally (at least once per heartbeat interval) send out an
`AppendEntries` RPC to all peers to prevent them from starting a new
election. If the leader has no new entries to send to a particular peer,
the `AppendEntries` RPC contains no entries, and is considered a
heartbeat.

Many students assumed that heartbeats were somehow "special"; that
when a peer receives a heartbeat, it should treat it differently from a
non-heartbeat `AppendEntries` RPC. In particular, many students would
simply reset their election timer when they received a heartbeat, and
then return success, without performing any of the checks specified in
Figure 2. This is *extremely dangerous*. By accepting the RPC, the
follower is implicitly telling the leader that their log matches the
leader's log up to and including the `prevLogIndex` included in the
`AppendEntries` arguments. Upon receiving the reply, the leader might
then decide (incorrectly) that some entry has been replicated to a
majority of servers, and start committing it.

Another issue many students had (often immediately after fixing the
issue above), was that, upon receiving a heartbeat, they would truncate
the follower's log following `prevLogIndex`, and then append any entries
included in the `AppendEntries` arguments. This is *also* not correct.
We can once again turn to Figure 2: 

> *If* an existing entry conflicts with a new one (same index but
> different terms), delete the existing entry and all that follow it.

The *if* here is crucial. If the follower has all the entries the leader
sent, the follower **MUST NOT** truncate its log. Any elements
*following* the entries sent by the leader **MUST** be kept. This is
because we could be receiving an outdated `AppendEntries` RPC from the
leader, and truncating the log would mean "taking back" entries that we
may have already told the leader that we have in our log.

You might argue that the students had no reason to take these
"shortcuts" in the first place. And technically, you would be right.
They should have followed Figure 2 to the letter, and they wouldn't have
this problem. Unfortunately, they didn't. This could be because they are
not used to following formal specifications, because Figure 2 doesn't
*look* like a formal specification, or because it's easy to miss some of
these subtle points, but it doesn't really matter. What matters is that
students (and most other programmers) *will* miss subtleties in the
specification. And Raft has a lot of them. That's not a great
combination.

### Debugging Raft

Inevitably, the first iteration of your Raft implementation will be
buggy. So will the second. And third. And fourth. In general, each one
will be less buggy than the previous one, and, from experience, most of
your bugs will be a result of not faithfully following Figure 2.

When debugging, Raft, there are generally three main sources of bugs:
livelocks, incorrect or incomplete RPC handlers, and failure to follow
The Rules. Deadlocks are also a common problem, but the can generally be
debugged by watching all your locks and unlocks, and figuring out which
locks you aren't releasing. Let us consider each of these three in turn:

#### Livelocks

When your system livelocks, every node in your system is doing
something, but collectively your nodes are in such a state that no
progress is being made. This can happen fairly easily in Raft,
especially if you do not follow Figure 2 religiously. One livelock
scenario comes up especially often; no leader is being elected, or once
a leader is elected, some other node starts an election, forcing the
recently elected leader to abdicate immediately.

There are many reasons why this scenario may come up, but there is a
handful of mistakes that we have seen numerous students make:

 - Make sure you reset your election timer *exactly* when Figure 2 says
   you should. Specifically, you should *only* restart your election
   timer a) if you get an `AppendEntries` RPC from the *current* leader
   (i.e., if the term in the `AppendEntries` arguments is outdated, you
   should *not* reset your timer); b) if you are starting an election;
   or c) if you *grant* a vote to another peer.

   This last case is especially important in unreliable networks where
   it is likely that followers have different logs; in those situations,
   you will often end up with only a small number of servers that a
   majority of servers are willing to vote for. If you reset the
   election timer whenever someone asks you to vote for them, this makes
   it equally likely for a server with an outdated log to step forward
   as for a server with a longer log. In fact, because there are so few
   servers with sufficiently up-to-date logs, those servers are quite
   unlikely to be able to hold an election in sufficient peace to be
   elected. If you follow the rule from Figure 2, the servers with the
   more up-to-date logs won't be interrupted by outdated servers'
   elections, and so are more likely to complete the election and become
   the leader.
 - Follow Figure 2's directions as to when you should start an election.
   In particular, note that if you are a candidate (i.e., you are
   currently running an election), but the election timer fires, you
   should start *another* election. This is important to avoid the
   system stalling due to delayed or dropped RPCs.
 - Ensure that you follow the second "Rules for Servers" *before*
   handling an incoming RPC. The second rule states:

   > If RPC request or response contains term `T > currentTerm`: set
   > `currentTerm = T`, convert to follower (§5.1)

   For example, if you have already voted in the current term, and an
   incoming `RequestVote` RPC has a higher term that you, you should
   *first* step down and adopt their term (thereby resetting
   `votedFor`), and *then* handle the RPC, which will result in you
   granting the vote!

#### Incorrect RPC handlers

Even though Figure 2 spells out exactly what each RPC handler should do,
some subtleties are still easy to miss. Here are a handful that we kept
seeing over and over again:

 - If a step says "reply false", this means you should *reply
   immediately*, and not perform any of the subsequent steps.
 - If you get an `AppendEntries` RPC with a `prevLogIndex` that points
   beyond the end of your log, you should handle it the same as if you
   did have that entry but the term did not match (i.e., reply false).
 - Check 2 for the `AppendEntries` RPC handler should be executed *even
   if the leader didn't send any entries*.
 - The `min` in the final step (#5) of `AppendEntries` is *necessary*,
   and it needs to be computed with the index of the last *new* entry.
   It is *not* sufficient to simply have the function that applies
   things from your log between `lastApplied` and `commitIndex` stop
   when it reaches the end of your log. This is because you may have
   entries in your log that differ from the leader's log *after* the
   entries that the leader sent you (which all match the ones in your
   log). Because #3 dictates that you only truncate your log *if* you
   have conflicting entries, those won't be removed, and if
   `leaderCommit` is beyond the entries the leader sent you, you may
   apply incorrect entries.
 - It is important to implement the "up-to-date log" check *exactly* as
   described in section 5.4. No cheating and just checking the length!

#### Failure to follow The Rules

While the Raft paper is very explicit about how to implement each RPC
handler, it also leaves the implementation of a number of rules and
invariants unspecified. These are listed in the "Rules for Servers"
block on the right hand side of Figure 2. While some of them are fairly
self-explanatory, the are also some that require designing your
application very carefully so that it does not violate The Rules:

 - If `commitIndex > lastApplied` *at any point* during execution, you
   should apply a particular log entry. It is not crucial that you do it
   straight away (for example, in the `AppendEntries` RPC handler), but
   it *is* important that you ensure that this application is only done
   by one entity. Specifically, you will need to either have a dedicated
   "applier", or to lock around these applies, so that some other
   routine doesn't also detect that entries need to be applied and also
   tries to apply.
 - If a leader sends out an `AppendEntries` RPC and it is rejected, but
   *not because of log inconsistency* (this can only happen if our term
   has passed), then you should immediately step down, and *not* update
   `nextIndex`. If you do, you could race with the resetting of
   `nextIndex` if you are re-elected immediately.
 - A leader is not allowed to update `commitIndex` to somewhere in a
   *previous* term (or, for that matter, a future term). Thus, as the
   rule says, you specifically need to check that `log[N].term ==
   currentTerm`.

One common source of confusion is the difference between `nextIndex` and
`matchIndex`. In particular, students often observe that `matchIndex =
nextIndex - 1`, and will initially simply not implement `matchIndex`.
This is not safe. While `nextIndex` and `matchIndex` are generally
updated at the same time to a similar value (specifically, `nextIndex =
matchIndex + 1`), the two serve quite different purposes. `nextIndex` is
a *guess* as to what prefix the leader shares with a given follower. It
is generally quite optimistic (we share everything), and is moved
backwards only on negative responses. For example, when a leader has
just been elected, `nextIndex` is set to be index index at the end of
the log. In a way, `nextIndex` is used for performance -- you only need
to send these things to this peer. `matchIndex` is used for safety. It
is a conservative *measurement* of what prefix of the log the leader
shares with a given follower. `matchIndex` cannot ever be set to a value
that is too high, as this may cause the `commitIndex` to be moved too
far forward. This is why `matchIndex` is initialized to -1 (i.e., we
agree on no prefix), and only updated when a follower *positively
acknowledges* an `AppendEntries` RPC.

#### An aside on optimizations

The Raft paper includes a couple of optional features of interest. In
6.824, we require the students to implement two of them: log compaction
(section 7) and accelerated log backtracking (top left hand side of page
8). The former is necessary to avoid the log growing without bound, and
the latter is useful for brining stale followers up to date quickly.

These features are not a part of "core Raft", and so do not receive as
much attention in the paper as the main consensus protocol. Log
compaction is covered fairly thoroughly (in Figure 13), but leaves out
some design details that are easy for a reader to get wrong:

 - When snapshotting application state, Raft needs to make sure that the
   application state corresponds to the state following some known index
   in the Raft log. This means that the application either needs to
   communicate to Raft what index the snapshot corresponds to, or that
   Raft needs to delay applying additional log entries until the
   snapshot has been completed.
 - The text does not discuss the recovery protocol for when a server
   crashes and comes back up now that snapshots are involved. In
   particular, since Raft state and snapshots are committed separately,
   a server could crash between persisting a snapshot and persisting the
   updated Raft state. This is a problem, because step 7 in Figure 13
   dictates that the Raft log covered by the snapshot *must be
   discarded*.
   
   If, when the server comes back up, it reads the updated snapshot, but
   the outdated log, it may end up applying some log entries *that are
   already contained within the snapshot*. This happens since the
   `commitIndex` and `lastApplied` are not persisted, and so Raft
   doesn't know that those log entries have already been applied. The
   fix for this is to introduce a piece of persistent state to Raft that
   records what "real" index the first entry in Raft's persisted log
   corresponds to. This can then be compared to the loaded snapshot's
   `lastIncludedIndex` to determine what elements at the head of the log
   to discard.

The accelerated log backtracking optimization is very underspecified,
probably because the authors do not see it as being necessary for most
deployments. It is not clear from the text exactly how the conflicting
index and term sent back from the client should be used by the leader to
determine what `nextIndex` to use. After some deliberation, the 6.824
staff have decided that what the authors *probably* intended, was the
following:

 - If the follower does not have `prevLogIndex` in its log, it should
   return with `conflictIndex = len(log)` and `conflictTerm = None`.
 - If the follower does have `prevLogIndex` in its log, but the term
   does not match, it should return `conflictTerm =
   log[prevLogIndex].Term`, and then search its log for the first index
   whose entry has term equal to `conflictTerm`.
 - Upon receiving a conflict response, the leader should first search
   its log for `conflictTerm`. If it finds an entry in its log with that
   term, it should set `nextIndex` to be the one beyond the index of the
   *last* entry in that term in its log.
 - If it does not find an entry with that term, it should set `nextIndex
   = conflictIndex`.

A half-way solution is to just use `conflictIndex`, which simplifies the
implementation, but then the leader will sometimes end up sending more
log entries to the follower than is strictly necessary to bring them up
to date.

### Did Paxos fare better?

Judging from the feedback from our students, the first Raft lab was
considerably more work than the equivalent Paxos lab from last year.
Students reported that while Raft was fairly easy to *understand*,
actually *implementing* it in the lab, and getting all the corner cases
correct, was both hard and extremely time-consuming. Admittedly, there
are some differences, namely that the Raft implementation also adds
sticky leader and persistence, but we do not believe those features
contribute particularly to Raft's implementation complexity. 

We originally switched to Raft because we believed that it would be
easier for the students to follow a complete design, than fiddling with
how to construct a log out of Paxos' single-value agreement. Since there
aren't any particularly good, complete descriptions of how to build
replicated state machines on top of Paxos, students had to cook up a
scheme themselves, which is an error-prone process.

Although Raft does give an end-to-end algorithm, and a very thorough
description of it, I think what has made it harder for students to
implement, is that Raft is tricky to build in a piece-wise fashion. It
is almost an all-or-nothing affair; either you follow every rule in the
paper to the letter, or you missed one somewhere and your entire
implementation is broken (and often in subtle and hard-to-debug ways).
The net result of this is that students ended up spending more time
debugging this lab than they did the Paxos lab, simply because at some
point they knew one "part" of their Paxos was correct (like single-value
agreement), and so could ignore that while debugging.

A natural question to ask then is: is Raft still "better" or "easier"
than Paxos from an educational point of view? While distributed
consensus is inherently complicated, the Raft authors have tried very
hard to make a protocol that is easily digestible and understandable, at
least in the general case, and they have arguably succeeded in doing
that. However, in the 6.824 lab, and when writing distributed systems in
"the real world", you are forced to tackle all the many nasty corner
cases, and that requires thinking very carefully about the tiniest
details in the underlying algorithm.

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

### Applications on top of Raft

When building a service on top of Raft (such as the key/value store in
the [second 6.824 Raft
lab](https://pdos.csail.mit.edu/6.824/labs/lab-kvraft.html), the
interaction between the service and the Raft log can be tricky to get
right. This section details some aspects of the development process that
we have found students to be confused about.

#### Applying client operations

The first point of confusion is usually how one would even implement an
application in terms of a replicated log. Students will often start by
having their service, whenever it receives a client request, send that
request to the leader, wait for Raft to apply something, do the
operation the client asked for, and then return to the client. While
this would be fine in a single-client system, it does not work for
concurrent clients.

Instead, the service should be constructed as a state machine where
client operations transition the machine from one state to another.
There's a loop somewhere that takes one client operation at the time (in
the same order on all servers -- this is where Raft comes in), and
applies each one to the state machine in order. This loop should be the
*only* part of your code that touches the application state (the
key/value mapping in our case). This means that your client-facing RPC
methods should simply submit the client's operation to Raft, and then
*wait* for that operation to be applied by this "applier loop". Only
when the client's command comes up should it be executed, and any return
values read out. Note that *this includes read requests*!

This brings up another issue that many students faced: how do you know
when a client operation has completed? In the case of no failures, this
is simple -- you just wait for the thing you put into the log to come
back out (i.e., be passed to `apply()`). When that happens, you return
the result to the client. However, what happens if there are failures?
For example, you may have been the leader when the client initially
contacted you, but someone else has since been elected, and the client
request you put in the log has been discarded. Clearly you need to have
the client try again, but how do you know when to tell them about the
error?

One simple way to solve this problem is to record where in the Raft log
the client's operation appears when you insert it. Once the operation at
that index is sent to `apply()`, you can tell whether or not the
client's operation succeeded based on whether the operation that came up
for that index is in fact the one you put there. If it isn't, a failure
has happened and an error can be returned to the client.

#### Duplicate detection

As soon as you have clients retry operations in the face of errors, you
need some kind of duplicate detection scheme -- if a client sends an
`APPEND` to your server, doesn't hear back, and so re-sends it to the
next server, your `apply()` function needs to ensure that the `APPEND`
isn't executed twice. To do so, you need some kind of unique identifier
for each client request, so that you can recognize if you have seen, and
more importantly, applied, a particular operation in the past.
Furthermore, this state needs to be a part of your state machine so that
all your Raft servers eliminate the *same* duplicates.

#### Hairy corner-cases

If your implementation follows the general outline given above, there
are at least two subtle issues you are likely to run into that may be
hard to identify without some serious debugging. To save you some time,
here they are:

**Re-appearing indices**:
Say that your Raft library has some method `Start()` that takes a
command, and return the index at which that command was placed in the
log (so that you know when to return to the client, as discussed above).
You might assume that you will never see `Start()` return the same index
twice, or at the very least, that if you see the same index again, the
command that first returned that index must have failed. Neither of
these things are true.

Consider the following scenario:
You have five servers, S1 through S5. Initially, S1 is the leader, and
its log is empty. Two client operations (C1 and C2) arrive on S1, and
`Start()` return 1 for the first, and 2 for the second. S1 sends out an
`AppendEntries` to S2 containing C1 and C2, but all its other messages
are lost. Next, S3 steps forward as a candidate. S1 and S2 won't vote
for S3, but S3, S4, and S5 all will, so S3 becomes the leader. Another
client request, C3 comes in to S3. S3 calls `Start()` (which returns 1),
and sends an `AppendEntries` to S1, who discards C1 and C2 from its log,
and adds C3. S3 then fails before sending `AppendEntries` to any other
servers. Next, S2 steps forward, and because its log is up-to-date, it
is elected leader. Another client request, C4, arrives at S1, which then
calls `Start()`. `Start()` returns 2 (which was also returned for
`Start(C2)`. All of S1's `AppendEntries` are dropped, and S2 steps
forward. S1 and S3 won't vote for S2, but S2, S4, and S5 all will, so S2
becomes leader. A client request C5 comes in to S2, `Start()` is called,
and returns 3. S2 then successfully sends `AppendEntries` to all the
servers, which S2 reports back to the servers by including an updated
`leaderCommit = 3` in the next heartbeat. Since S2's log is `[C1 C2
C5]`, this means that the entry that committed (and was applied at all
servers, including S1) at index 2 is C2. This despite the fact that C4
was the last client operation to have returned index 2 at S1.

**The four-way deadlock**:
All credit for finding this goes to [Steven
Allen](http://stebalien.com/), another 6.824 TA. He found the following
nasty four-way deadlock that you can easily get into when building
applications on top of Raft.

Your Raft code, however it is structured, likely has a `Start()`-like
function that allows the application to add new commands to the Raft
log. It also likely has a loop that, when `commitIndex` is updated,
calls `apply()` on the application for every element in the log between
`lastApplied` and `commitIndex`. These routines probably both take some
lock `a`. In your Raft-based application, you probably call Raft's
`Start()` function somewhere in your RPC handlers, and you have some
code somewhere else that is informed whenever Raft applies a new log
entry. Since these two need to communicate (i.e., the RPC method needs
to know when the operation it put into the log completes), they both
probably take some lock `b`.

In Go, these four code segments probably look something like this:

```go
func (a *App) RPC(args interface{}, reply interface{}) {
    // ...
    a.mutex.Lock()
    i := a.raft.Start(args)
    // update some data structure so that apply knows to poke us later
    a.mutex.Unlock()
    // wait for apply to poke us
    return
}
```

```go
func (r *Raft) Start(cmd interface{}) int {
    r.mutex.Lock()
    // do things to start agreement on this new command
    // store index in the log where cmd was placed
    r.mutex.Unlock()
    return index
}
```

```go
func (a *App) apply(index int, cmd interface{}) {
    a.mutex.Lock()
    switch cmd := cmd.(type) {
    case GetArgs:
        // do the get
	// see who was listening for this index
	// poke them all with the result of the operation
    // ...
    }
    a.mutex.Unlock()
}
```

```go
func (r *Raft) AppendEntries(...) {
    // ...
    r.mutex.Lock()
    // ...
    for r.lastApplied < r.commitIndex {
      r.lastApplied++
      r.app.apply(r.lastApplied, r.log[r.lastApplied])
    }
    // ...
    r.mutex.Unlock()
}
```

Consider now if the system is in the following state:

 - `App.RPC` has just taken `a.mutex` and called `Raft.Start`
 - `Raft.Start` is waiting for `r.mutex`
 - `Raft.AppendEntries` is holding `r.mutex`, and has just called
   `App.apply`

We now have a deadlock, because:

 - `Raft.AppendEntries` won't release the lock until `App.apply` returns.
 - `App.apply` can't return until it gets `a.mutex`.
 - `a.mutex` won't be released until `App.RPC` returns.
 - `App.RPC` won't return until `Raft.Start` returns.
 - `Raft.Start` can't return until it gets `r.mutex`.
 - `Raft.Start` has to wait for `Raft.AppendEntries`.

There are a couple of ways to get around this problem. The easiest one
is to take `a.mutex` *after* calling `a.raft.Start` in `App.RPC`.
However, this means that `App.apply` may be called for the operation
that `App.RPC` just called `Raft.Start` on *before* `App.RPC` has a
chance to record the fact that it wishes to be notified.
Another scheme that may yield a neater design is to have a single,
dedicated thread calling `r.app.apply` from `Raft`. This thread could be
notified every time `commitIndex` is updated, and would then not need to
hold a lock in order to apply, breaking the deadlock.

### Student top Raft Q&A

[Q](https://piazza.com/class/igs35ab0zvja8?cid=140)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=142)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=147)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=170)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=174)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=184)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=188)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=207)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=211)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=223)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=226)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=242)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=393)
[Q](https://piazza.com/class/igs35ab0zvja8?cid=425)
