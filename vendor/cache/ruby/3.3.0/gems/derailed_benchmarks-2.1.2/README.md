## Derailed Benchmarks

A series of things you can use to benchmark a Rails or Ruby app.

![](http://media.giphy.com/media/lfbxexWy71b6U/giphy.gif)

[![CircleCI](https://circleci.com/gh/zombocom/derailed_benchmarks/tree/main.svg?style=svg)](https://circleci.com/gh/zombocom/derailed_benchmarks/tree/main)
[![Help Contribute to Open Source](https://www.codetriage.com/schneems/derailed_benchmarks/badges/users.svg)](https://www.codetriage.com/schneems/derailed_benchmarks)

## Compatibility/Requirements

For some benchmarks, not all, you'll need to verify you have a working version of curl on your OS:

```
$ which curl
/usr/bin/curl
$ curl -V
curl 7.64.1 #...
```

## Install

Put this in your gemfile:

```ruby
gem 'derailed_benchmarks', group: :development
```

Then run `$ bundle install`.

While executing your commands you may need to use `bundle exec` before typing the command.

To use all profiling methods available also add:

```ruby
gem 'stackprof', group: :development
```

You must be using Ruby 2.1+ to install these libraries. If you're on an older version of Ruby, what are you waiting for?

## Use

There are two ways to benchmark an app. Derailed can either try to boot your web app and run requests against it while benchmarking, or it can statically give you more information about the dependencies that are in your Gemfile. Booting your app will always be more accurate, but if you cannot get your app to run in production locally, you'll still find the static information useful.

## Static Benchmarking

This section covers how to get memory information from your Gemfile without having to boot your app.

All commands in this section will begin with `$ derailed bundle:`

For more information on the relationship between memory and performance please read/watch [How Ruby Uses Memory](http://www.schneems.com/2015/05/11/how-ruby-uses-memory.html).

### Memory used at Require time

Each gem you add to your project can increase your memory at boot. You can get visibility into the total memory used by each gem in your Gemfile by running:

```
$ bundle exec derailed bundle:mem
```

This will load each of your gems in your Gemfile and see how much memory they consume when they are required. For example if you're using the `mail` gem. The output might look like this

```
$ bundle exec derailed bundle:mem
TOP: 54.1836 MiB
  mail: 18.9688 MiB
    mime/types: 17.4453 MiB
    mail/field: 0.4023 MiB
    mail/message: 0.3906 MiB
  action_view/view_paths: 0.4453 MiB
    action_view/base: 0.4336 MiB
```

_Aside: A "MiB", which is the [IEEE] and [IEC] symbol for Mebibyte, is 2<sup>20</sup> bytes / 1024 Kibibytes (which are in turn 1024 bytes)._

[IEEE]: https://en.wikipedia.org/wiki/IEEE_1541-2002
[IEC]: https://en.wikipedia.org/wiki/IEC_80000-13

Here we can see that `mail` uses 18MiB, with the majority coming from `mime/types`. You can use this information to prune out large dependencies you don't need. Also if you see a large memory use by a gem that you do need, please open up an issue with that library to let them know (be sure to include reproduction instructions). Hopefully as a community we can identify memory hotspots and reduce their impact. Before we can fix performance problems, we need to know where those problems exist.

By default this task will only return results from the `:default` and `"production"` groups. If you want a different group you can run with.

```
$ bundle exec derailed bundle:mem development
```

You can use `CUT_OFF=0.3` to only show files that have above a certain memory usage, this can be used to help eliminate noise.

Note: This method won't include files in your own app, only items in your Gemfile. For that you'll need to use `bundle exec derailed exec mem`. See below for more info.

The same file may be required by several libraries, since Ruby only requires files once, the cost is only associated with the first library to require a file. To make this more visible duplicate entries will list all the parents they belong to. For example both `mail` and `fog` require `mime/types. So it may show up something like this in your app:

```
$ bundle exec derailed bundle:mem
TOP: 54.1836 MiB
  mail: 18.9688 MiB
    mime/types: 17.4453 MiB (Also required by: fog/storage)
    mail/field: 0.4023 MiB
    mail/message: 0.3906 MiB
```

That way you'll know that simply removing the top level library (mail) would not result in a memory reduction. The output is truncated after the first two entries:


```
fog/core: 0.9844 MiB (Also required by: fog/xml, fog/json, and 48 others)
fog/rackspace: 0.957 MiB
fog/joyent: 0.7227 MiB
  fog/joyent/compute: 0.7227 MiB
```

If you want to see everything that requires `fog/core` you can run `CUT_OFF=0 bundle exec derailed bundle:mem` to get the full output that you can then grep through manually.

Update: While `mime/types` looks horrible in these examples, it's been fixed. You can add this to the top of your gemfile for free memory:

```ruby
gem 'mime-types', [ '~> 2.6', '>= 2.6.1' ], require: 'mime/types/columnar'
```

### Objects created at Require time

To get more info about the objects, using [memory_profiler](https://github.com/SamSaffron/memory_profiler), created when your dependencies are required you can run:

```
$ bundle exec derailed bundle:objects
```

This will output detailed information about objects created while your dependencies are loaded

```
Measuring objects created by gems in groups [:default, "production"]
Total allocated 433895
Total retained 100556

allocated memory by gem
-----------------------------------
  24369241  activesupport-4.2.1
  15560550  mime-types-2.4.3
   8103432  json-1.8.2
```

Once you identify a gem that creates a large amount of memory using `$ bundle exec derailed bundle:mem` you can pull that gem into it's own Gemfile and run `$ bundle exec derailed bundle:objects` to get detailed information about it. This information can be used by contributors and library authors to identify and eliminate object creation hotspots.


By default this task will only return results from the `:default` and `"production"` groups. If you want a different group you can run with.

```
$ bundle exec derailed bundle:objects development
```

Note: This method won't include files in your own app, only items in your Gemfile. For that you'll need to use `bundle exec derailed exec objects`. See below for more info.


## Dynamic app Benchmarking

This benchmarking will attempt to boot your Rails app and run benchmarks against it. Unlike the static benchmarking with `$ bundle exec derailed bundle:*` these will include information about your specific app. The pro is you'll get more information and potentially identify problems in your app code, the con is that it requires you to be able to boot and run your application in a `production` environment locally, which for some apps is non-trivial.

You may want to check out [mini-profiler](https://github.com/MiniProfiler/rack-mini-profiler), here's a [mini-profiler walkthrough](http://www.justinweiss.com/articles/a-new-way-to-understand-your-rails-apps-performance/). It's great and does slightly different benchmarking than what you'll find here.

### Running in Production Locally.

Before you want to attempt any dynamic benchmarks, you'll need to boot your app in `production` mode. We benchmark using `production` because it is close to your deployed performance. This section is more a collection of tips rather than a de-facto tutorial.

For starters try booting into a console:

```
$ RAILS_ENV=production rails console
```

You may get errors, complaining about not being able to connect to the `production` database. For this, you can either create a local database with the name of your production database, or you can copy the info from your `development` group to your `production` group in your `database.yml`.

You may be missing environment variables expected in `production` such as `SECRET_KEY_BASE`. For those you can either commit them to your `.env` file (if you're using one). Or add them directly to the command:

```
$ SECRET_KEY_BASE=foo RAILS_ENV=production rails console
```

Once you can boot a console in production, you'll need to be able to boot a server in production

```
$ RAILS_ENV=production rails server
```

You may need to disable enforcing SSL or other domain restrictions temporarily. If you do these, don't forget to add them back in before deploying any code (eek!).

You can get information from STDOUT if you're using `rails_12factor` gem, or from `log/production.log` by running

```
$ tail -f log/production.log
```

Once you've fixed all errors and you can run a server in production, you're almost there.

### Running Derailed Exec

You can run commands against your app by running `$ derailed exec`. There are sections on setting up Rack and using authenticated requests below. You can see what commands are available by running:

```
$ bundle exec derailed exec --help
  $ derailed exec perf:allocated_objects  # outputs allocated object diff after app is called TEST_COUNT times
  $ derailed exec perf:app  # runs the performance test against two most recent commits of the current app
  $ derailed exec perf:gc  # outputs GC::Profiler.report data while app is called TEST_COUNT times
  $ derailed exec perf:heap  # heap analyzer
  $ derailed exec perf:ips  # iterations per second
  $ derailed exec perf:library  # runs the same test against two different branches for statistical comparison
  $ derailed exec perf:mem  # show memory usage caused by invoking require per gem
  $ derailed exec perf:mem_over_time  # outputs memory usage over time
  $ derailed exec perf:objects  # profiles ruby allocation
  $ derailed exec perf:stackprof  # stackprof
  $ derailed exec perf:test  # hits the url TEST_COUNT times
  $ derailed exec perf:heap_diff  # three heaps generation for comparison
```

Instead of going over each command we'll look at common problems and which commands are best used to diagnose them. Later on we'll cover all of the environment variables you can use to configure derailed benchmarks in it's own section.


### Is my app leaking memory?

If your app appears to be leaking ever increasing amounts of memory, you'll want to first verify if it's an actual unbound "leak" or if it's just using more memory than you want. A true memory leak will increase memory use forever, most apps will increase memory use until they hit a "plateau". To diagnose this you can run:

```
$ bundle exec derailed exec perf:mem_over_time
```

This will boot your app and hit it with requests and output the memory to stdout (and a file under ./tmp). It may look like this:

```
$ bundle exec derailed exec perf:mem_over_time
Booting: production
Endpoint: "/"
PID: 78675
103.55078125
178.45703125
179.140625
180.3671875
182.1875
182.55859375
# ...
183.65234375
183.26171875
183.62109375
```

Here we can see that while the memory use is increasing, it levels off around 183 MiB. You'll want to run this task using ever increasing values of `TEST_COUNT=` for example

```
$ TEST_COUNT=5000 bundle exec derailed exec perf:mem_over_time
$ TEST_COUNT=10_000 bundle exec derailed exec perf:mem_over_time
$ TEST_COUNT=20_000 bundle exec derailed exec perf:mem_over_time
```

Adjust your counts appropriately so you can get results in a reasonable amount of time. If your memory never levels off, congrats! You've got a memory leak! I recommend copying and pasting values from the file generated into google docs and graphing it so you can get a better sense of the slope of your line.

If you don't want it to generate a tmp file with results run with `SKIP_FILE_WRITE=1`.

If you're pretty sure that there's a memory leak, but you can't confirm it using this method. Look at the environment variable options below, you can try hitting a different endpoint etc.

## Dissecting a Memory Leak

If you've identified a memory leak, or you simply want to see where your memory use is coming from you'll want to use

```
$ bundle exec derailed exec perf:objects
```

This task hits your app and uses memory_profiler to see where objects are created. You'll likely want to run once, then run it with a higher `TEST_COUNT` so that you can see hotspots where objects are created on __EVERY__ request versus just maybe on the first.


```
$ TEST_COUNT=10 bundle exec derailed exec perf:objects
```

This is an expensive operation, so you likely want to keep the count lowish. Once you've identified a hotspot read [how ruby uses memory](http://www.sitepoint.com/ruby-uses-memory/) for some tips on reducing object allocations.

This is similar to `$ bundle exec derailed bundle:objects` however it includes objects created at runtime. It's much more useful for actual production performance debugging, the other is more useful for library authors to debug.

## I want a Heap Dump

If you're still struggling with runtime memory you can generate a heap dump that can later be analyzed using [heapy](https://github.com/schneems/heapy).

```
$ bundle exec derailed exec perf:heap
Booting: production
Heap file generated: "tmp/2015-10-01T12:31:03-05:00-heap.dump"

Analyzing Heap
==============
Generation:  0 object count: 209307
Generation: 35 object count: 31236
Generation: 36 object count: 36705
Generation: 37 object count: 1301
Generation: 38 object count: 8

Try uploading "tmp/2015-10-01T12:31:03-05:00-heap.dump" to http://tenderlove.github.io/heap-analyzer/
```

For more help on getting data from a heap dump see

```
$ heapy --help
```

### I want more heap dumps

When searching for a leak, you can use heap dumps for comparison to see what is
retained. See [Analyzing memory heaps](https://medium.com/klaxit-techblog/tracking-a-ruby-memory-leak-in-2021-9eb56575f731#875b)
(inspired from [SamSaffron's original idea](https://speakerdeck.com/samsaffron/why-ruby-2-dot-1-excites-me?slide=27))
for a clear example. You can generate 3 dumps (one every `TEST_COUNT` calls) using the
next command:

```
$ bundle exec derailed exec perf:heap_diff
Endpoint: "/"
Running 1000 times
Heap file generated: "tmp/2021-05-06T15:19:26+02:00-heap-0.ndjson"
Running 1000 times
Heap file generated: "tmp/2021-05-06T15:19:26+02:00-heap-1.ndjson"
Running 1000 times
Heap file generated: "tmp/2021-05-06T15:19:26+02:00-heap-2.ndjson"

Diff
====
Retained STRING 90 objects of size 4790/91280 (in bytes) at: /Users/ulysse/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/rack-2.2.3/lib/rack/utils.rb:461
Retained ICLASS 20 objects of size 800/91280 (in bytes) at: /Users/ulysse/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/sinatra-contrib-2.0.8.1/lib/sinatra/namespace.rb:198
Retained DATA 20 objects of size 1360/91280 (in bytes) at: /Users/ulysse/.rbenv/versions/2.7.2/lib/ruby/2.7.0/monitor.rb:238
Retained STRING 20 objects of size 800/91280 (in bytes) at: /Users/ulysse/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/rack-protection-2.0.8.1/lib/rack/protection/xss_header.rb:20
Retained STRING 10 objects of size 880/91280 (in bytes) at: /Users/ulysse/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/newrelic_rpm-5.4.0.347/lib/new_relic/agent/transaction.rb:890
Retained CLASS 10 objects of size 4640/91280 (in bytes) at: /Users/ulysse/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/sinatra-contrib-2.0.8.1/lib/sinatra/namespace.rb:198
Retained IMEMO 10 objects of size 480/91280 (in bytes) at: /Users/ulysse/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/sinatra-2.0.8.1/lib/sinatra/base.rb:1017
...

Run `$ heapy --help` for more options

Also read https://medium.com/klaxit-techblog/tracking-a-ruby-memory-leak-in-2021-9eb56575f731#875b to understand better what you are reading.
```

### Memory Is large at boot.

Ruby memory typically goes in one direction, up. If your memory is large when you boot the application it will likely only increase. In addition to debugging memory retained from dependencies obtained while running `$ derailed bundle:mem` you'll likely want to see how your own files contribute to memory use.

This task does essentially the same thing, however it hits your app with one request to ensure that any last minute `require`-s have been called. To execute you can run:


```
$ bundle exec derailed exec perf:mem

TOP: 54.1836 MiB
  mail: 18.9688 MiB
    mime/types: 17.4453 MiB
    mail/field: 0.4023 MiB
    mail/message: 0.3906 MiB
  action_view/view_paths: 0.4453 MiB
    action_view/base: 0.4336 MiB
```

You can use `CUT_OFF=0.3` to only show files that have above a certain memory usage, this can be used to help eliminate noise.

If your application code is extremely large at boot consider using `$ derailed exec perf:objects` to debug low level object creation.

## My app is Slow

Well...aren't they all. If you've already looked into decreasing object allocations, you'll want to look at where your app is spending the most amount of code. Once you know that, you'll know where to spend your time optimising.

One technique is to use a "sampling" stack profiler. This type of profiling looks at what method is being executed at a given interval and records it. At the end of execution it counts all the times a given method was being called and shows you the percent of time spent in each method. This is a very low overhead method to looking into execution time. Ruby 2.1+ has this available in gem form it's called [stackprof](https://github.com/tmm1/stackprof). As you guessed you can run this with derailed benchmarks, first add it to your gemfile `gem "stackprof", group: :development` then execute:

```
$ bundle exec derailed exec perf:stackprof
==================================
  Mode: cpu(1000)
  Samples: 16067 (1.07% miss rate)
  GC: 2651 (16.50%)
==================================
     TOTAL    (pct)     SAMPLES    (pct)     FRAME
      1293   (8.0%)        1293   (8.0%)     block in ActionDispatch::Journey::Formatter#missing_keys
       872   (5.4%)         872   (5.4%)     block in ActiveSupport::Inflector#apply_inflections
       935   (5.8%)         802   (5.0%)     ActiveSupport::SafeBuffer#safe_concat
       688   (4.3%)         688   (4.3%)     Temple::Utils#escape_html
       578   (3.6%)         578   (3.6%)     ActiveRecord::Attribute#initialize
      3541  (22.0%)         401   (2.5%)     ActionDispatch::Routing::RouteSet#url_for
       346   (2.2%)         346   (2.2%)     ActiveSupport::SafeBuffer#initialize
       298   (1.9%)         298   (1.9%)     ThreadSafe::NonConcurrentCacheBackend#[]
       227   (1.4%)         227   (1.4%)     block in ActiveRecord::ConnectionAdapters::PostgreSQLAdapter#exec_no_cache
       218   (1.4%)         218   (1.4%)     NewRelic::Agent::Instrumentation::Event#initialize
      1102   (6.9%)         213   (1.3%)     ActiveSupport::Inflector#apply_inflections
       193   (1.2%)         193   (1.2%)     ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper#deprecate_string_options
       173   (1.1%)         173   (1.1%)     ActiveSupport::SafeBuffer#html_safe?
       308   (1.9%)         171   (1.1%)     NewRelic::Agent::Instrumentation::ActionViewSubscriber::RenderEvent#metric_name
       159   (1.0%)         159   (1.0%)     block in ActiveRecord::Result#hash_rows
       358   (2.2%)         153   (1.0%)     ActionDispatch::Routing::RouteSet::Generator#initialize
       153   (1.0%)         153   (1.0%)     ActiveRecord::Type::String#cast_value
       192   (1.2%)         143   (0.9%)     ActionController::UrlFor#url_options
       808   (5.0%)         127   (0.8%)     ActiveRecord::LazyAttributeHash#[]
       121   (0.8%)         121   (0.8%)     PG::Result#values
       120   (0.7%)         120   (0.7%)     ActionDispatch::Journey::Router::Utils::UriEncoder#escape
      2478  (15.4%)         117   (0.7%)     ActionDispatch::Journey::Formatter#generate
       115   (0.7%)         115   (0.7%)     NewRelic::Agent::Instrumentation::EventedSubscriber#event_stack
       114   (0.7%)         114   (0.7%)     ActiveRecord::Core#init_internals
       263   (1.6%)         110   (0.7%)     ActiveRecord::Type::Value#type_cast
      8520  (53.0%)         102   (0.6%)     ActionView::CompiledTemplates#_app_views_repos__repo_html_slim__2939326833298152184_70365772737940
```

From here you can dig into individual methods.

## Is this perf change faster?

Micro benchmarks might tell you at the code level how much faster something is, but what about the overall application speed. If you're trying to figure out how effective a performance change is to your application, it is useful to compare it to your existing app performance. To help you with that you can use:

```
$ bundle exec derailed exec perf:ips
Endpoint: "/"
Calculating -------------------------------------
                 ips     1.000  i/100ms
-------------------------------------------------
                 ips      3.306  (± 0.0%) i/s -     17.000
```

This will hit an endpoint in your application using [benchmark-ips](https://github.com/evanphx/benchmark-ips). In "iterations per second" a higher value is always better. You can run your code change several times using this method, and then run your "baseline" codebase (without your changes) to see how it affects your overall performance. You'll want to run and record the results several times (including the std deviation) so you can help eliminate noise. Benchmarking is hard, this technique isn't perfect but it's definitely better than nothing.

If you care you can also run pure benchmark (without ips):

```
$ bundle exec derailed exec perf:test
```

But I wouldn't, benchmark-ips is a better measure.

### Configuring `benchmark-ips`

The `benchmark-ips` gem allows for a number of test run customizations, and `derailed_benchmarks` exposes a few of them via environment variables.

- `IPS_WARMUP`: number of seconds spent warming up the app, defaullt is `2`
- `IPS_TIME`: number of seconds to run ips benchmark for after warm up, defaullt is `5`
- `IPS_SUITE`: custom suite to use to run test
- `IPS_ITERATIONS`: number of times to run the test, displaying that last result, defaullt is `1`

## I made a patch to to Rails how can I tell if it made my Rails app faster and test for statistical significance

When you're trying to submit a performance patch to rails/rails then they'll likely ask you for a benchmark. While you can sometimes provide a microbenchmark, a real world full stack request/response test is the gold standard.

That's what this section is about. You'll need a rails app, ideally one you can open source (see [example apps](http://codetriage.com/example_app) if you need inspiration for extracting your private code into something external).

Then you'll need to fork rails and make a branch. Then point your rails app to your branch in your gemfile

```
gem 'rails', github: "<github username>/rails", branch: "<your branch name>"
```

or point it at your local copy:

```
gem 'rails', path: "<path/to/your/local/copy/rails>"
```

To run your tests within the context of your current app/repo:

```
$ bundle exec derailed exec perf:app
```

This will automatically test the two latest commits of your library/current directory.

If you'd like to test the Rails library instead, make sure that `ENV[DERAILED_PATH_TO_LIBRARY]` is unset.

```
$ bundle exec derailed exec perf:library
```

This will automatically test the two latest commits of Rails.

If you would also like to compare against different SHAs you can manually specify them:

```
$ SHAS_TO_TEST="7b4d80cb373e,13d6aa3a7b70" bundle exec derailed exec perf:library
```

Use a comma to seperate your branch names with the `SHAS_TO_TEST` env var, or omit the env var to use the last 2 git commits.

If you only include one SHA, then derailed will grab the latest commit and compare it to that SHA.

These tests might take a along time to run so the output is stored on disk incase you want to see them in the future, they're at `tmp/compare_branches/<timestamp>` and labeled with the same names as your commits.

When the test is done it will output which commit "won" and by how much:

```
❤️ ❤️ ❤️  (Statistically Significant) ❤️ ❤️ ❤️

[f1ab117] (11.3844 seconds) "I am the new commit" ref: "winner"
  FASTER 🚀🚀🚀 by:
    1.0062x [older/newer]
    0.6147% [(older - newer) / older * 100]
[5594a2d] (11.4548 seconds) "Old commit" ref: "loser"

Iterations per sample:
Samples: 100

Test type: Kolmogorov Smirnov
Confidence level: 99.0 %
Is significant? (max > critical): true
D critical: 0.2145966026289347
D max: 0.26

Histograms (time ranges are in seconds):

   [f1ab117] description:                                        [5594a2d] description:
     "I am the new commit"                                         "Old commit"
                  ┌                                        ┐                    ┌                                        ┐
   [11.2 , 11.28) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 12                             [11.2 , 11.28) ┤▇▇▇▇ 3
   [11.28, 11.36) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 22                 [11.28, 11.36) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 19
   [11.35, 11.43) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 30       [11.35, 11.43) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 17
   [11.43, 11.51) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 17                       [11.43, 11.51) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 25
   [11.5 , 11.58) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 13                           [11.5 , 11.58) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 15
   [11.58, 11.66) ┤▇▇▇▇▇▇▇ 6                                     [11.58, 11.66) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 13
   [11.65, 11.73) ┤ 0                                            [11.65, 11.73) ┤▇▇▇▇ 3
   [11.73, 11.81) ┤ 0                                            [11.73, 11.81) ┤▇▇▇▇ 3
   [11.8 , 11.88) ┤ 0                                            [11.8 , 11.88) ┤▇▇▇ 2
                  └                                        ┘                    └                                        ┘
                             # of runs in range                                            # of runs in range
```

You can provide this to the Rails team along with the example app you used to benchmark (so they can independently verify if needed).

Generally performance patches have to be weighted in terms of how much they help versus how large/difficult/gnarly the patch is. If the above example was a really tiny patch and it was in a common component, then half a percent might be a justafiable increase. If it was a huge re-write then it's likely going to be closed. In general I tend to not submit patches unless I'm seeing `>= 1%` performance increases.

You can use this to test changes in other libraries that aren't rails, you just have to tell it the path to the library you want to test against with the `DERAILED_PATH_TO_LIBRARY` env var.

> To get the best results before running tests you should close all programs on your laptop, turn on a program to prevent your laptop from going to sleep (or increase your sleep timer). Make sure it's plugged into a power outlet and  go grab a cup of coffee. If you do anything on your laptop while this test is running you risk the chance of skewing your results.

As the test is executing, intermediate results will be printed every 50 iterations.

## Environment Variables

All the tasks accept configuration in the form of environment variables.

### Increasing or decreasing test count `TEST_COUNT`

For tasks that are run a number of times you can set the number using `TEST_COUNT` for example:

```
$ TEST_COUNT=100_000 bundle exec derailed exec perf:test
```

### Warming up your app before measuring with `WARM_COUNT`

When you are measuring the long term performance of an application, especially if you're using jit you may want to let the application "warm up" without measuring this time. To allow for this you can specify `WARM_COUNT` and the application will be called that number of times before any measurements are taken.

```
$ WARM_COUNT=5_000 bundle exec derailed exec perf:test
Warming up app: 5000 times
# ...
```

### Hitting a different endpoint with `PATH_TO_HIT`

By default tasks will hit your homepage `/`. If you want to hit a different url use `PATH_TO_HIT` for example if you wanted to go to `users/new` you can execute:

```
$ PATH_TO_HIT=/users/new bundle exec derailed exec perf:mem
```

This method accepts a full uri. For example, allowing you to hit a subdomain endpoint:

```
$ PATH_TO_HIT=http://subdomain.lvh.me:3000/users/new bundle exec derailed exec perf:mem
```

Beware that you cannot combine a full uri with `USE_SERVER`.

### Setting HTTP headers

You can specify HTTP headers by setting `HTTP_<header name>` variables. Example:

```
$ HTTP_AUTHORIZATION="Basic YWRtaW46c2VjcmV0\n" \
  HTTP_USER_AGENT="Mozilla/5.0" \
  PATH_TO_HIT=/foo_secret bundle exec derailed exec perf:ips
```

### Using a real web server with `USE_SERVER`

All tests are run without a webserver (directly using `Rack::Mock` by default), if you want to use a webserver set `USE_SERVER` to a Rack::Server compliant server, such as `webrick`.

```
$ USE_SERVER=webrick bundle exec derailed exec perf:mem
```

Or

```
$ USE_SERVER=puma bundle exec derailed exec perf:mem
```

This boots a webserver and hits it using `curl` instead of in memory. This is useful if you think the performance issue is related to your webserver.

Note: this plugs in the given webserver directly into rack, it doesn't use any `puma.config` file etc. that you have set-up. If you want to do this, i'm open to suggestions on how (and pull requests)

### Excluding ActiveRecord

By default, derailed will load ActiveRecord if the gem is included as a dependency.  It is included by default, if you just include the `rails` gem.  If you are using a different ORM, you will either need to only include the `railties` gem, or set the `DERAILED_SKIP_ACTIVE_RECORD` environment variable.

```
$ DERAILED_SKIP_ACTIVE_RECORD=true
```

Alternatively, use the `DERAILED_SKIP_RAILS_REQUIRES` environment variable to have derailed not require any Rails gems. Your app will then need to require them as part of its boot sequence.

### Running in a different environment

Tests run against the production environment by default, but it's easy to
change this if your app doesn't run locally with `RAILS_ENV` set to
`production`. For example:

```
$ RAILS_ENV=development bundle exec derailed exec perf:mem
```

## perf.rake

If you want to customize derailed, you'll need to create a `perf.rake` file at the root of the directory you're trying to benchmark.

It is possible to run benchmarks directly using rake

```
$ cat <<  EOF > perf.rake
  require 'bundler'
  Bundler.setup

  require 'derailed_benchmarks'
  require 'derailed_benchmarks/tasks'
EOF
```

The file should look like this:

```
$ cat perf.rake
  require 'bundler'
  Bundler.setup

  require 'derailed_benchmarks'
  require 'derailed_benchmarks/tasks'
```

This is done so the benchmarks will be loaded before your application, this is important for some benchmarks and less for others. This also prevents you from accidentally loading these benchmarks when you don't need them.

Then you can execute your commands via rake.

To find out the tasks available you can use `$ rake -f perf.rake -T` which essentially says use the file `perf.rake` and list all the tasks.

```
$ rake -f perf.rake -T
```

## Rack Setup

Using Rails? You don't need to do anything special. If you're using Rack, you need to tell us how to boot your app. In your `perf.rake` file add a task:

```ruby
namespace :perf do
  task :rack_load do
    DERAILED_APP = # your code here
  end
end
```

Set the constant `DERAILED_APP` to your Rack app. See [schneems/derailed_benchmarks#1](https://github.com/schneems/derailed_benchmarks/pull/1) for more info.

An example of setting this up could look like:


```ruby
# perf.rake

require 'bundler'
Bundler.setup

require 'derailed_benchmarks'
require 'derailed_benchmarks/tasks'

namespace :perf do
  task :rack_load do
    require_relative 'lib/application'
    DERAILED_APP = MyApplication::Routes
  end
end
```

## Authentication

If you're trying to test an endpoint that has authentication you'll need to tell your task how to bypass that authentication. Authentication is controlled by the `DerailedBenchmarks.auth` object. There is a built in support for Devise. If you're using some other authentication method, you can write your own authentication strategy.

To enable authentication in a test run with:

```
$ USE_AUTH=true bundle exec derailed exec perf:mem
```

See below how to customize authentication.

### Authentication with Devise

If you're using devise, there is a built in auth helper that will detect the presence of the devise gem and load automatically.

Create a `perf.rake` file at your root.

```
$ cat perf.rake
```

If you want you can customize the user that is logged in by setting that value in your `perf.rake` file.

```ruby
DerailedBenchmarks.auth.user = -> { User.find_or_create!(twitter: "schneems") }
```

You will need to provide a valid user, so depending on the validations you have in your `user.rb`, you may need to provide different parameters.

If you're trying to authenticate a non-user model, you'll need to write your own custom auth strategy.

### Custom Authentication Strategy

To implement your own authentication strategy You will need to create a class that [inherits from auth_helper.rb](lib/derailed_benchmarks/auth_helper.rb). You will need to implement a `setup` and a `call` method. You can see an example of [how the devise auth helper was written](lib/derailed_benchmarks/auth_helpers/devise.rb) and [how it can be done for Clearance](https://gist.github.com/zavan/f4d34dd86bf825db549a0ac28c7e10d5). You can put this code in your `perf.rake` file.

```ruby
class MyCustomAuth < DerailedBenchmarks::AuthHelper
  def setup
    # initialize code here
  end

  def call(env)
    # log something in on each request
    app.call(env)
  end
end
```

The devise strategy works by enabling test mode inside of the Rack request and inserting a stub user. You'll need to duplicate that logic for your own authentication scheme if you're not using devise.

Once you have your class, you'll need to set `DerailedBenchmarks.auth` to a new instance of your class. In your `perf.rake` file add:

```ruby
DerailedBenchmarks.auth = MyCustomAuth.new
```

Now on every request that is made with the `USE_AUTH` environment variable set, the `MyCustomAuth#call` method will be invoked.

## License

MIT

## Acknowledgements

Most of the commands are wrappers around other libraries, go check them out. Also thanks to [@tenderlove](https://twitter.com/tenderlove) as I cribbed some of the Rails init code in `$ rake perf:setup` from one of his projects.

kthksbye [@schneems](https://twitter.com/schneems)
