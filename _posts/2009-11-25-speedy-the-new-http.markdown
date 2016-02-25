---
layout: post
title: SPeeDY - The new HTTP?
date: '2009-11-25 11:50:06'
---

Google have been coming with a lot of new cool projects lately - From Chrome and Chrome OS to Wave and Social Search. Following this innovative trend, they have now announced that they're working on a possible replacement for HTTP. Actually, it is not as much a replacement as it is an augmentation or "fix". SPDY will still be using the headers and basic structure of HTTP, but will treat that structure quite differently and introduce several enhancements to make it more efficient and more suitable for the contemporary web context.

Google argues that we need a new protocol for web traffic because of the way the web has changed over the last decade. Nowadays, pages use both multimedia and several externally linked files - something which HTTP was not optimized for. More specifically - HTTP does not allow:

 - Fetching several resources through a single HTTP connection
 - Push-like behavior from the server to the client
 - Lack of native, and compulsory, compression of packet contents - especially headers
 - Statelessness - HTTP does not "remember" anything from previous exchanges. This makes for redundant information such as certain almost static headers to be resent unnecessarily

Although several other projects have tried to come up with an appropriate replacement for the HTTP protocol, Google now believe that they have found one that is suitable. The SPDY project aims to accomplish several things; for example, a 50% decrease in latency for online request-response cycles and near-transparent transfer from the old technology to the new one.

This latter point is quite interesting, and has been the reason why many other similar proposals have failed. Far too many protocols attempt to reinvent the wheel, but Google has decided to retain the TCP protocol as the underlying transportation agent, and to minimize the impact on developers and end-users. This is achieved by the SPDY protocol avoiding any changes to the way the data is handled on both end-points, only the protocol in between, so that web developers won't have to change a thing on the server side. The only changes that are needed are in the browsers and the web server itself.

The reduction in latency will be primarily by enforcing compression on headers and body, slicing away unnecessary header tags and allowing several resources to be fetched in a single TCP request to avoid packet overhead. Google has also decided to take some steps to improve the overall quality of the protocol as a whole by introducing SSL as the rule, and non-SSL as the exception (if it will be allowed at all); as well as cutting down the protocol definition so that the implementation will be much simpler.

Overall, SPDY promises a lot, and looks very promising - All that remains is to see whether server and browser developers will join the cause and develop working implementations of the draft for testing. Knowing Google, they will probably release support for it in both Chrome and an "experimental" web server that will probably be released soon.

One major obstacle for its popularity though is that the premise of multiple resources in a single TCP stream, and a move away from the stringent request/response cycle of current HTTP sessions means substantial changes will be made to the web servers to allow for this kind of behavior. Hopefully Google will release their testing server to the public soon so we can start to see test implementations of the technology, and how hard or easy it will be to implement.

For more info on the technology, have a look at the [SPDY Whitepaper](http://dev.chromium.org/spdy/spdy-whitepaper).