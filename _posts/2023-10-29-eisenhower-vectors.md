---
layout: post
title: "Eisenhower vectors"
date: '2023-10-29 10:04:37'
shared:
---

This past week, during a team off-site at work, I was re-introduced to
[the Eisenhower matrix]; a handy device for prioritizing tasks and
deciding how and when to handle them. It gets its name from [this quote]
from US President Dwight D. Eisenhower:

> I have two kinds of problems, the urgent and the important.
> The urgent are not important, and the important are never urgent.

(In the speech, Eisenhower in turn attributes it to a "former college
president", and this general principle is also known by other names like
"ABCD analysis", but let's stick with the Eisenhower nomenclature).

At its core, the basic idea is that every task can be be classified as
important (or not), and urgent (or not), and that these two are
independent variables. Things can be urgent without being important, and
vice-versa. Once classified in this way, the rule of thumb is to **do**
things that are both important _and_ urgent, **schedule** things that
are important but not urgent, **delegate** things that are urgent but
not important, and **drop** tasks that are neither important or urgent.

While we were going through some exercises on prioritization using the
Eisenhower matrix, it struck me that there's a facet of tasks that
factors into their priority but isn't represented in the matrix: a
task's **potential**. Some tasks are neither important nor urgent _right
now_, but have the potential to become one or the other at some future
point in time. And this potential should be factored into that task's
priority.

(You could argue that a task's potential should factor into how
important it is, but I think it's a useful exercise to treat potential
as a third facet so that you are forced to take it into account.)

So, let me introduce you to the _Eisenhower vector_. Like [(Euclidian)
(bound) vectors][vec], an Eisenhower vector is an arrow with a point of
origin, a direction, and a magnitude (or length). The point of origin
represents the _current_ classification of the task along the importance
and urgency axes of the Eisenhower matrix. The direction signifies how
the importance and urgency is expected to change over time. And the
magnitude dictates how quickly you think the task is likely to develop
in that direction. For example:

> ![Eisenhower vector for a task whose origin is not urgent or important, but is trending towards important](gfx/eisenhower-vector-more.svg)
> An Eisenhower vector for a task that is currently not important or
> urgent, but is gradually becoming more important.

This task would normally be dropped, since it's not important or urgent.
But, we're expecting that it will become more important over time,
potentially crossing the boundary into important-but-not-urgent
territory. And as a result, it may deserve to be scheduled (with a lower
priority) rather than dropped. Compare that to this task:

> ![Eisenhower vector for a task whose origin is urgent, not important, and rapidly trending towards less urgent](gfx/eisenhower-vector-less.svg)
> An Eisenhower vector for a task that is currently quite urgent, not
> important, and expected to rapidly become less urgent.

It's currently very urgent (a customer has sent you four emails in the
past five minutes), but you expect that that urgency will fade rather
quickly if the task is _not_ done immediately. This, too, should affect
the task's prioritization relative to other tasks. Given the perceived
urgency, the customer in question probably won't be happy about you not
doing it (they never are when things feel urgent), but it may still be
worthwhile down-prioritizing the task over something else that's
currently less urgent, but will remain as urgent.

Note that unlike the original Eisenhower matrix, Eisenhower vectors do
not have a general rule for what the direction and magnitude imply as
far as task management goes (i.e., do/schedule/delegate/drop). Instead,
they are a means to help you visualize (and thus bring into focus) a
task's trend-line so that you don't forget about that part while
prioritizing. If you want a very non-scientific rule of thumb, consider
prioritizing Eisenhower vectors as though they were a point at the
mid-point of the arrow.

That's all &mdash; happy tasking!

[the Eisenhower matrix]: https://todoist.com/productivity-methods/eisenhower-matrix
[this quote]: https://www.presidency.ucsb.edu/documents/address-the-second-assembly-the-world-council-churches-evanston-illinois
[vec]: https://en.wikipedia.org/wiki/Euclidean_vector
