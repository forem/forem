Sidekiq
==============

[![Gem Version](https://badge.fury.io/rb/sidekiq.svg)](https://rubygems.org/gems/sidekiq)
![Build](https://github.com/mperham/sidekiq/workflows/CI/badge.svg)

Simple, efficient background processing for Ruby.

Sidekiq uses threads to handle many jobs at the same time in the
same process.  It does not require Rails but will integrate tightly with
Rails to make background processing dead simple.

Performance
---------------

Version |	Latency | Garbage created for 10k jobs	| Time to process 100k jobs |	Throughput | Ruby
-----------------|------|---------|---------|------------------------|-----
Sidekiq 6.0.2    | 3 ms	| 156 MB  | 14.0 sec| **7100 jobs/sec** | MRI 2.6.3
Sidekiq 6.0.0    | 3 ms	| 156 MB  | 19 sec  | 5200 jobs/sec | MRI 2.6.3
Sidekiq 4.0.0    | 10 ms	| 151 MB  | 22 sec  | 4500 jobs/sec |
Sidekiq 3.5.1    | 22 ms	| 1257 MB | 125 sec | 800 jobs/sec |
Resque 1.25.2    |  -	  | -       | 420 sec | 240 jobs/sec |
DelayedJob 4.1.1 |  -   | -       | 465 sec | 215 jobs/sec |

This benchmark can be found in `bin/sidekiqload` and assumes a Redis network latency of 1ms.

Requirements
-----------------

- Redis: 4.0+
- Ruby: MRI 2.5+ or JRuby 9.2+.

Sidekiq 6.0 supports Rails 5.0+ but does not require it.


Installation
-----------------

    bundle add sidekiq


Getting Started
-----------------

See the [Getting Started wiki page](https://github.com/mperham/sidekiq/wiki/Getting-Started) and follow the simple setup process.
You can watch [this YouTube playlist](https://www.youtube.com/playlist?list=PLjeHh2LSCFrWGT5uVjUuFKAcrcj5kSai1) to learn all about
Sidekiq and see its features in action.  Here's the Web UI:

![Web UI](https://github.com/mperham/sidekiq/raw/main/examples/web-ui.png)


Want to Upgrade?
-------------------

I also sell Sidekiq Pro and Sidekiq Enterprise, extensions to Sidekiq which provide more
features, a commercial-friendly license and allow you to support high
quality open source development all at the same time.  Please see the
[Sidekiq](https://sidekiq.org/) homepage for more detail.

Subscribe to the **[quarterly newsletter](https://tinyletter.com/sidekiq)** to stay informed about the latest
features and changes to Sidekiq and its bigger siblings.


Problems?
-----------------

**Please do not directly email any Sidekiq committers with questions or problems.**  A community is best served when discussions are held in public.

If you have a problem, please review the [FAQ](https://github.com/mperham/sidekiq/wiki/FAQ) and [Troubleshooting](https://github.com/mperham/sidekiq/wiki/Problems-and-Troubleshooting) wiki pages.
Searching the [issues](https://github.com/mperham/sidekiq/issues) for your problem is also a good idea.

Sidekiq Pro and Sidekiq Enterprise customers get private email support.  You can purchase at https://sidekiq.org; email support@contribsys.com for help.

Useful resources:

* Product documentation is in the [wiki](https://github.com/mperham/sidekiq/wiki).
* Occasional announcements are made to the [@sidekiq](https://twitter.com/sidekiq) Twitter account.
* The [Sidekiq tag](https://stackoverflow.com/questions/tagged/sidekiq) on Stack Overflow has lots of useful Q &amp; A.

Every Friday morning is Sidekiq happy hour: I video chat and answer questions.
See the [Sidekiq support page](https://sidekiq.org/support.html) for details.

Contributing
-----------------

Please see [the contributing guidelines](https://github.com/mperham/sidekiq/blob/main/.github/contributing.md).


License
-----------------

Please see [LICENSE](https://github.com/mperham/sidekiq/blob/main/LICENSE) for licensing details.


Author
-----------------

Mike Perham, [@getajobmike](https://twitter.com/getajobmike) / [@sidekiq](https://twitter.com/sidekiq), [https://www.mikeperham.com](https://www.mikeperham.com) / [https://www.contribsys.com](https://www.contribsys.com)
