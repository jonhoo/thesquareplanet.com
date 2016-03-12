---
layout: post
title: Students' Guide to Raft
date: '2016-03-06 16:17:10'
---

For the past few months, I have been a Teaching Assistant for MIT's
[6.824 Distributed Systems](https://pdos.csail.mit.edu/6.824/) class.
The class has traditionally had a number of labs building on the Paxos
consensus algorithm, but this year, we decided to make the move to
[Raft](https://raft.github.io/). Raft was "designed to be easy to
understand", and our hope was that the change might make the students'
lives easier.

This post, and the accompanying [Instructors' Guide to Raft](post_url
instructors-guide-to-raft) post, chronicles our journey with Raft, and
will hopefully be useful to implementers of the Raft protocol and
students trying to get a better understanding of Raft's internals. If
you are looking for a Paxos vs Raft comparison, or for a more
pedagogical analysis of Raft, you should go read the Instructors' Guide.
Finally, the bottom of this post contains a list of questions commonly
asked by 6.824 students, as well as answers to those questions. If you
run into an issue that is not listed in the main content of this post,
check out the [Q&A]({{ page.url }}/#student-top-raft-qa).

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

Raft, for those of you who are just getting to know it, is best
described by the text on the protocol's [web
site](https://raft.github.io/):

> Raft is a consensus algorithm that is designed to be easy to
> understand. It's equivalent to Paxos in fault-tolerance and
> performance. The difference is that it's decomposed into relatively
> independent subproblems, and it cleanly addresses all major pieces
> needed for practical systems. We hope Raft will make consensus
> available to a wider audience, and that this wider audience will be
> able to develop a variety of higher quality consensus-based systems
> than are available today.

Visualizations like [this one](http://thesecretlivesofdata.com/raft/)
give a good overview of the principal components of the protocol, and
the paper gives good intuition for why the various pieces are needed. If
you haven't already read the [extended Raft
paper](http://ramcloud.stanford.edu/raft.pdf), you should go read that
before continuing this article, as I will assume a decent familiarity
with Raft.

As with all distributed consensus protocols, the devil is very much in
the details. In the steady state where there are no failures, Raft's
behavior is easy to understand, and can be explained in an intuitive
manner. For example, it is simple to see from the visualizations that,
assuming no failures, a leader will eventually be elected, and
eventually all operations sent to the leader will be applied by the
followers in the right order. However, when delayed messages, network
partitions, and failed servers are introduced, each and every if, but,
and and, become crucial. In particular, there are a number of bugs that
we see repeated over and over again, simply due to misunderstandings or
oversights when reading the paper. This problem is not unique to Raft,
and is one that comes up in all complex distributed systems that provide
correctness.

### Implementing Raft

The ultimate guide to Raft is in Figure 2 of the Raft paper. This figure
specifies the behavior of every RPC exchanged between Raft servers, and
also gives various invariant that servers should maintain, and when
certain actions should occur. We will be talking about Figure 2 *a lot*
in the rest of this article. It needs to be followed *to the letter*.

Figure 2 defines what every server should do, in ever state, for every
incoming RPC, as well as when certain other things should happen (such
as when it is safe to apply an entry in the log). At first, one might be
tempted to treat Figure 2 as sort of an informal guide; you read it
once, and then start coding up an implementation that follows roughly
what it says to do. Doing this, you will quickly get up and running with
a mostly working Raft implementation. And then the problems start.

In fact, Figure 2 is extremely precise, and every single statement
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

### Debugging Raft

Inevitably, the first iteration of your Raft implementation will be
buggy. So will the second. And third. And fourth. In general, each one
will be less buggy than the previous one, and, from experience, most of
your bugs will be a result of not faithfully following Figure 2.

When debugging, Raft, there are generally four main sources of bugs:
livelocks, incorrect or incomplete RPC handlers, failure to follow The
Rules, and term confusion. Deadlocks are also a common problem, but the
can generally be debugged by watching all your locks and unlocks, and
figuring out which locks you aren't releasing. Let us consider each of
these three in turn:

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

#### Term confusion

Term confusion refers to servers getting confused by RPCs that come from
old terms. In general, this is not a problem when receiving an RPC,
since the rules in Figure 2 say exactly what you should do when you see
an old term. However, Figure 2 generally doesn't discuss what you should
do when you get old RPC *replies*. From experience, we have found that
by far the simplest thing to do is to first record the term in the reply
(it may be higher than your current term), and then to compare the
current term with the term you sent in your original RPC. If the two are
different, drop the reply and return. *Only* if the two terms are the
same should you continue processing the reply. There may be further
optimizations you can do here with some clever protocol reasoning, but
this approach seems to work well. And *not* doing it leads down a long,
winding path of blood, sweat, tears and despair.

A related, but not identical problem is that of assuming that your state
has not changed between when you sent the RPC, and when you received the
reply. A good example of this is setting `matchIndex = nextIndex - 1`,
or `matchIndex = len(log)` when you receive a response to an RPC. This
is *not* safe, because both of those values could have been updated
since when you sent the RPC. Instead, the correct thing to do is update
`matchIndex` to be `prevLogIndex + len(entries[])` from the arguments
you sent in the RPC originally.

#### An aside on optimizations

The Raft paper includes a couple of optional features of interest. In
6.824, we require the students to implement two of them: log compaction
(section 7) and accelerated log backtracking (top left hand side of page
8). The former is necessary to avoid the log growing without bound, and
the latter is useful for bringing stale followers up to date quickly.

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

For 6.824 we are using [Piazza](https://piazza.com/class/igs35ab0zvja8)
for class communication and Q&A. Over the course of the semester, a
number of good questions have been asked that may be of use to others
trying to come to grips with Raft. A selection of the questions and
answers are given below. These are all adapted from the questions and
answers given by 6.824 students and TAs.

> Assume we have three servers, and that S0 is elected leader. S0
> receives some commands from a client and adds them to its log (say,
> 1:100, 1:101, and 1:102, on the form term:command). S0 is then
> immediately partitioned from the rest of the servers before
> propagating those entries to any clients.
>
> Next, S1 is elected leader right after the partitioning of S0. It gets
> two commands, 2:103 and 2:104, and replicates them to S2 (and thus
> also commits them). Immediately after this, S1 is partitioned off, and
> S0 is re-connected. S2 would now be elected leader, since logs on S0
> are not up to date.
>
> S0 would learn the commit index of S2 is 2 from its `AppendEntries`,
> but it should not commit any command from its log, because its log
> doesn't match that of S2. If there is no new command from clients,
> when should we erase all conflicting log entries on S0?

You're right that S0 will learn the new `leaderCommit` from S2's
heartbeat. But before any follower updates its `commitIndex` to match
the leader's, what does it need to do? Take another look at the order of
instructions in the receiver implementation for the `AppendEntries` RPC
in Figure 2. It's very specific about when a follower's conflicting log
entries should be erased.

> In figure 8 of the raft paper: (d) seems bad because [2] has been
> committed, but gets rolled back. What are they saying prevents (d) from
> happening? What prevents S5 from being elected in step (d)?

[2] can't be committed in term 4, because Raft never explicitly commits
old entries (only implicitly by the Log Matching Property as explained
in section 5.4.2). So in step (c), S1 would only be able to commit 2 if
it were also able to commit 4, which would then exclude S5 from being an
eligible candidate.

> When is current term supposed to be incremented? If my Raft instances
> are left idle (i.e., no client commands), they do not eventually agree
> on the current term. I'm incrementing the `currentTerm` field whenever
> I start an election, but I only do it for the candidate (sending out
> the votes). Is this correct, or should I be incrementing `currentTerm`
> for all the servers I send the request to?

You're right that you should increment `currentTerm` when the current
term times out and you start a new election. However, followers also
have to update their terms at some point, or else you'll end up with
servers agreeing on the same leader, but for different terms. Just
incrementing on all servers that you send the request to won't work,
because the voting servers might already have different terms, and might
end up incrementing twice if they receive the same two `RequestVotes`
for the same term, etc.

To figure out when and how you should update `currentTerm` (on all
servers), see the rule for all servers in Figure 2 of the Raft paper:
"If RPC request or response contains term `T > currentTerm`: set
`currentTerm = T`, convert to follower."

> I'm quite confused about the difference between the `RequestVote` RPC
> arguments and the `AppendEntries` RPC arguments. `RequestVote` has
> `lastLogIndex/Term`, while `AppendEntries` has `prevLogIndex/Term`.
> Are these equivalent?
>
> I'm trying to mentally think of an example: If I have entries
> 0,1,2,3,4 in my log, then I'm assuming my `lastLogIndex` would be 4.
> But would `prevLogIndex` be the same thing? Does this differ for each
> follower you send it to? (i.e., do we use `nextIndex[]`/`matchIndex[]`
> to help determine `prevLogIndex`?)

When a candidate sends a `RequestVote` RPC, the `lastLogIndex` should be
the index of its last log entry (so 5 in your example).

For `AppendEntries`, the `prevLogIndex/Term` should refer to the log entry
immediately preceding the first element of the `entries[]` field of the
RPC arguments in the leader's log. Suppose the leader has log entries
0,1,2,3,4,5,6,7,8 and `nextIndex[i]` is 6 for some follower `i`. The
leader wants to send entries 6,7,8 to that follower. The leader would
copy 6,7,8 to `entries[]`, and set `prevLogIndex` to 5.

> What exactly is meant by "volatile state" in the Raft paper? Is this
> data lost if the server storing it crashes? If so, why are
> `commitIndex` and `lastApplied` volatile? Shouldn't they be
> persistent?

Yes, "volatile" means it is lost if there's a crash.

`commitIndex` is volatile because Raft can figure out a correct value
for it after a reboot using just the persistent state. Once a leader
successfully gets a new log entry committed, it knows everything before
that point is also committed. A follower that crashes and comes back up
will be told about the right `commitIndex` whenever the current leader
sends it an `AppendEntries` RPC.

`lastApplied` starts at zero after a reboot because the Figure 2 design
assumes the service (e.g., a key/value database) doesn't keep any
persistent state. Thus its state needs to be completely recreated by
replaying all log entries. If the service does keep persistent state, it
is expected to persistently remember how far in the log it has executed,
and to ignore entries before that point. Either way it's safe to start
with `lastApplied = 0` after a reboot.

> According to Figure 2, persistent state is saved before responding to
> RPCs, but a leader never receive RPC from other raft servers when it's
> working normally. This means if we only save persistent state when
> receiving `AppendEntries` or `RequestVote`, a leader never gets a
> chance to store persistent state, which is kind of weird...
> Or do the RPCs including ones called by clients?

For simplicity, you should save Raft's persistent state just after any
change to that state. The most important thing is that you save
persistent state before you make it possible for anything else to
*observe* the new state, i.e., before you send an RPC, reply to an RPC,
return from `Start()`, or apply a command to the state machine.

If a server changes persistent state, but then crashes before it gets
the chance to save it, that's fine -- it's as if the crash happened
before the state was changed. However, if the server changes persistent
state, *makes it visible*, and *then* crashes before it saves it, that's
*not* fine -- forgetting that persistent state may cause it to violate
protocol invariants (for example, it could vote for two different
candidates in the same term if it forgot `votedFor`).

> Figure 2 says "if an existing entry conflicts with a new one", delete
> it and everything that follows. But inside Section 5.3, it suggests we
> should find the latest log entry where the two logs agree.
>
> What is the difference between Bullet point #2 and #3? Right now, I'm
> basically checking the value at `prevLogIndex+1`, and seeing if it's
> equal to the leader's term. If it isn't, I delete it and everything
> following it. But based on 5.3, should I actually be going through
> the entire log from the end and checking if they agree?

I think you are just mixing up the roles of the follower and the leader
in this case. The leader is essentially probing the follower's log to
find the last point where the two agree. This is what the `nextIndex`
variable is used for. The follower helps the leader do this by a)
rejecting any `AppendEntries` RPCs that doesn't immediately follow a
point where the two agree (this is #2), and b) overwriting any following
entries in its log once #2 is satisfied (this is #3).

To put it simply, #2 makes sure that the entries before the ones
contained in the `AppendEntries` RPC from the leader match on the leader
and the follower. #3 ensures that the entries in the follower's log
following the prefix the leader and follower agree about are the same as
the entries the leader holds in its log.

> I'm a little confused; what the difference is between a log entry that
> is "applied" and one that is "committed". Are all applied entries
> committed, but not the other way around? When does a committed entry
> become applied?

Any log entry that you have applied to the application state machine is
"applied". An entry should never be applied unless it has already been
committed. An entry can be committed, but not yet applied. You will
likely apply committed entries very soon after they become committed.

> Why is it necessary to check if log[N].term == currentTerm? In the
> "Leaders" section of the "Rules for Servers" part of Figure 2, why is
> it necessary to only update `matchIndex` if `log[N].term ==
> currentTerm`? What should happen if `log[N].term != currentTerm`?

Raft leaders can't be sure an entry is actually committed (and will not
ever be changed in the future) if it's not from their current term,
which Figure 8 from the paper illustrates. One way to think about it is
that a follower only shows their "allegiance" to leader A by replicating
a log record from A's current term. If they haven't, and a follower has
only replicated a log entry from an earlier term, then another candidate
B can come along with a conflicting entry in their log (same index but
higher term) and "steal" the votes from a majority of such followers:
B's log is more-up-to-date than the followers by virtue of having a
higher-termed entry in the last spot, so the followers have to vote for
it. Then B, now a leader, overwrites that original log record with their
own higher-termed one.

Note that this can't happen if the follower replicates a log entry from
A's current term. In this case, since A's current term is the highest at
which a command was issued, a candidate's log can only be more
up-to-date than the follower's if it includes that log entry, so any new
candidate this follower votes for will never overwrite it.

> In `AppendEntries`, if the `prevLogTerm/Index` matches, I get rid of
> the log after the `prevlogIndex`, and just append the entries from the
> RPC arguments:
>
> ```go
>   rf.Log = rf.Log[:args.PrevLogIndex + 1]
>   rf.Log = append(rf.Log, args.Entries ...)
> ```
>
> However, what if the `AppendEntries` RPCs are received out-of-order?
>
> Say that there are 3 machines, and S1 is leader. All this is in term 1.
>
> ```
>   S1: [C1]   S2: [C1]   S3: [C1]
> ```
>
>  - S1 receives requests C2-5, making the logs:
>
>    ```
>     S1: [C1,C2,C3,C4,C5]   S2: [C1]   S3: [C1]
>    ```
>
>  - S1 sends out `AppendEntries` RPCs with:
>
>    ```javascript
>    {
>      prevLogIndex: 1,
>      prevLogTerm: 1,
>      entries: [C2, C3],
>    }
>    ```
>
>  - S1 sends out `AppendEntries` RPCs with:
>
>    ```javascript
>    {
>      prevLogIndex: 1,
>      prevLogTerm: 1,
>      entries: [C2, C3, C4, C5],
>    }
>    ```
>
>    This could happen if there's a pause between leader receiving C3
>    and C4, and the other servers haven't responded to the first RPC
>    yet.
>  - S1's second `AppendEntries` RPC arrives, so we have:
>
>    ```
>     S2: [C1,C2,C3,C4,C5]   S3: [C1,C2,C3,C4,C5]
>    ```
>
>    They both respond positively.
>  - S1 commits up to C5, and responds back to client.
>  - Now, S1's first `AppendEntries` RPC arrives at S2 and S3. S2 and S3
>    revert back to `[C1,C2,C3]`.
>  - S1 crashes.
>  - **S2 can now become leader and the committed rule is broken!**
>
> Why can this not happen in Raft?

This is a very good question. The answer lies in the exact wording of
point #3 in the `AppendEntries` RPC definition in Figure 2 in the paper:
"If an existing entry conflicts with a new one (same index but different
terms), delete the existing entry and all that follow it."

Note that the rule starts with "*if* an existing entry conflicts". This
is important exactly for the scenario you outline above. Here's what
should happen + some intuition: There is a rule in Raft that the
`commitIndex` can never be reduced (intuitively because we cannot
un-apply a log entry). We know that if our `commitIndex` is ever
changed so that it points to somewhere in the log, *all* entries before
that point will *never* change ever again. Without the *if* in the
aforementioned rule from Figure 2, this rule would be violated, because,
as you point out, it could cause a follower to uncommit entries that it
has already committed.

The *if* is what saves us. To see why, consider what happens if
`prevLogIndex`'s term matches `prevLogTerm` (and the leader has an
up-to-date term of course). This means that whatever the leader sent us
*must* be a prefix of the "true" log (that is, what `leaderCommit`
applies to). This is true both for the second ("long") `AppendEntries`
RPC, and the first ("short") `AppendEntries` RPC. It follows from this
that the entries in the "short" RPC must be a prefix of those in the
"long" RPC. A consequence of this is that we don't match the if from the
rule — no existing entry conflicts with a new one, and we should
therefore *not* truncate our log, but simply append to it. Now, we
aren't invalidating our old `commitIndex`, and all is well in the world.
