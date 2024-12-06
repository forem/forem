# SidekiqUniqueJobs

[![Join the chat at https://gitter.im/mhenrixon/sidekiq-unique-jobs](https://badges.gitter.im/mhenrixon/sidekiq-unique-jobs.svg)](https://gitter.im/mhenrixon/sidekiq-unique-jobs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) ![Build Status](https://github.com/mhenrixon/sidekiq-unique-jobs/actions/workflows/rspec.yml/badge.svg?branch=master) [![Code Climate](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs.svg)](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs) [![Test Coverage](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/badges/coverage.svg)](https://codeclimate.com/github/mhenrixon/sidekiq-unique-jobs/coverage)

## Support Me

Want to show me some ❤️ for the hard work I do on this gem? You can use the following PayPal link: [https://paypal.me/mhenrixon1](https://paypal.me/mhenrixon1). Any amount is welcome and let me tell you it feels good to be appreciated. Even a dollar makes me super excited about all of this.

<!-- MarkdownTOC -->

- [Introduction](#introduction)
- [Usage](#usage)
  - [Installation](#installation)
  - [Add the middleware](#add-the-middleware)
  - [Your first worker](#your-first-worker)
- [Requirements](#requirements)
- [Locks](#locks)
  - [Until Executing](#until-executing)
    - [Example worker](#example-worker)
  - [Until Executed](#until-executed)
    - [Example worker](#example-worker-1)
  - [Until Expired](#until-expired)
    - [Example worker](#example-worker-2)
  - [Until And While Executing](#until-and-while-executing)
    - [Example worker](#example-worker-3)
  - [While Executing](#while-executing)
    - [Example worker](#example-worker-4)
  - [Custom Locks](#custom-locks)
- [Conflict Strategy](#conflict-strategy)
  - [log](#log)
  - [raise](#raise)
  - [reject](#reject)
  - [replace](#replace)
  - [reschedule](#reschedule)
  - [Custom Strategies](#custom-strategies)
  - [3 Cleanup Dead Locks](#3-cleanup-dead-locks)
- [Debugging](#debugging)
  - [Sidekiq Web](#sidekiq-web)
  - [Reflections \(metrics, logging, etc.\)](#reflections-metrics-logging-etc)
    - [after_unlock_callback_failed](#after_unlock_callback_failed)
    - [error](#error)
    - [execution_failed](#execution_failed)
    - [lock_failed](#lock_failed)
    - [locked](#locked)
    - [reschedule_failed](#reschedule_failed)
    - [rescheduled](#rescheduled)
    - [timeout](#timeout)
  - [unlock_failed](#unlock_failed)
  - [unlocked](#unlocked)
  - [unknown_sidekiq_worker](#unknown_sidekiq_worker)
    - [Show Locks](#show-locks)
    - [Show Lock](#show-lock)
- [Testing](#testing)
  - [Validating Worker Configuration](#validating-worker-configuration)
  - [Uniqueness](#uniqueness)
- [Configuration](#configuration)
  - [Other Sidekiq gems](#other-sidekiq-gems)
    - [apartment-sidekiq](#apartment-sidekiq)
    - [sidekiq-global_id](#sidekiq-global_id)
    - [sidekiq-status](#sidekiq-status)
  - [Global Configuration](#global-configuration)
    - [debug_lua](#debug_lua)
    - [lock_timeout](#lock_timeout)
    - [lock_ttl](#lock_ttl)
    - [enabled](#enabled)
    - [logger](#logger)
    - [max_history](#max_history)
    - [reaper](#reaper)
    - [reaper_count](#reaper_count)
    - [reaper_interval](#reaper_interval)
    - [reaper_timeout](#reaper_timeout)
    - [lock_prefix](#lock_prefix)
  - [lock_info](#lock_info)
  - [Worker Configuration](#worker-configuration)
    - [lock_info](#lock_info-1)
    - [lock_prefix](#lock_prefix-1)
    - [lock_ttl](#lock_ttl-1)
    - [lock_timeout](#lock_timeout-1)
    - [unique_across_queues](#unique_across_queues)
    - [unique_across_workers](#unique_across_workers)
  - [Finer Control over Uniqueness](#finer-control-over-uniqueness)
  - [After Unlock Callback](#after-unlock-callback)
- [Communication](#communication)
- [Contributing](#contributing)
- [Contributors](#contributors)

<!-- /MarkdownTOC -->

## Introduction

This gem adds unique constraints to sidekiq jobs. The uniqueness is achieved by creating a set of keys in redis based off of `queue`, `class`, `args` (in the sidekiq job hash).

By default, only one lock for a given hash can be acquired. What happens when a lock can't be acquired is governed by a chosen [Conflict Strategy](#conflict-strategy) strategy. Unless a conflict strategy is chosen (?)

This is the documentation for the `main` branch. You can find the documentation for each release by navigating to its tag.

Here are links to some of the old versions

- [v7.0.12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v7.0.12)
- [v6.0.25](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.25)
- [v5.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10)
- [v4.0.18](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.18)

## Usage

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-unique-jobs'
```

And then execute:

```bash
bundle
```

### Add the middleware

Before v7, the middleware was configured automatically. Since some people reported issues with other gems (see [Other Sidekiq Gems](#other-sidekiq-gems)) it was decided to give full control over to the user.

*NOTE* if you want to use the reaper you also need to configure the server middleware.

The following shows how to modify your `config/initializers/sidekiq.rb` file to use the middleware. [Here is a full example.](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/myapp/config/initializers/sidekiq.rb#L12)

```ruby
require "sidekiq-unique-jobs"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"], driver: :hiredis }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"], driver: :hiredis }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end
```

### Your first worker

The lock type most likely to be is `:until_executed`. This type of lock creates a lock from when `UntilExecutedWorker.perform_async` is called until right after `UntilExecutedWorker.new.perform` has been called.

```ruby
# frozen_string_literal: true

class UntilExecutedWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  def perform
    logger.info("cowboy")
    sleep(1) # hardcore processing
    logger.info("beebop")
  end
end
```

You can read more about the worker configuration in [Worker Configuration](#worker-configuration) below.

## Requirements

- Sidekiq `>= 5.0` (`>= 5.2` recommended)
- Ruby:
  - MRI `>= 2.5` (`>= 2.6` recommended)
  - JRuby `>= 9.0` (`>= 9.2` recommended)
  - Truffleruby
- Redis Server `>= 3.2` (`>= 5.0` recommended)
- [ActiveJob officially not supported][48]
- [redis-namespace officially not supported][49]

See [Sidekiq requirements][24] for detailed requirements of Sidekiq itself (be sure to check the right sidekiq version).

## Locks

### Until Executing

A lock is created when `UntilExecuting.perform_async` is called. Then it is either unlocked when `lock_ttl` is hit or before Sidekiq calls the `perform` method on your worker.

#### Example worker

```ruby
class UntilExecuting
  include Sidekiq::Workers

  sidekiq_options lock: :until_executing

  def perform(id)
    # Do work
  end
end
```

**NOTE** this is probably not so good for jobs that shouldn't be running simultaneously (aka slow jobs).

The reason this type of lock exists is to fix the following problem: [sidekiq/issues/3471](https://github.com/mperham/sidekiq/issues/3471#issuecomment-300866335)

### Until Executed

A lock is created when `UntilExecuted.perform_async` is called. Then it is either unlocked when `lock_ttl` is hit or when Sidekiq has called the `perform` method on your worker.

#### Example worker

```ruby
class UntilExecuted
  include Sidekiq::Workers

  sidekiq_options lock: :until_executed

  def perform(id)
    # Do work
  end
end
```

### Until Expired

This lock behaves identically to the [Until Executed](#until-executed) except for one thing. This job won't be unlocked until the expiration is hit. For jobs that need to run only once per day, this would be the perfect lock. This way, we can't create more jobs until one day after this job was first pushed.

#### Example worker

```ruby
class UntilExpired
  include Sidekiq::Workers

  sidekiq_options lock: :until_expired, lock_ttl: 1.day

  def perform
    # Do work
  end
end
```

### Until And While Executing

This lock is a combination of two locks (`:until_executing` and `:while_executing`). Please see the configuration for [Until Executing](#until-executing) and [While Executing](#while-executing)

#### Example worker

```ruby
class UntilAndWhileExecutingWorker
  include Sidekiq::Workers

  sidekiq_options lock: :until_and_while_executing,
                  lock_timeout: 2,
                  on_conflict: {
                    client: :log,
                    server: :raise
                  }
  def perform(id)
    # Do work
  end
end
```

### While Executing

These locks are put on a queue without any type of locking mechanism, the locking doesn't happen until Sidekiq pops the job from the queue and starts processing it.

#### Example worker

```ruby
class WhileExecutingWorker
  include Sidekiq::Workers

  sidekiq_options lock: :while_executing,
                  lock_timeout: 2,
                  on_conflict: {
                    server: :raise
                  }
  def perform(id)
    # Do work
  end
end
```

**NOTE** Unless a conflict strategy of `:raise` is specified, if lock fails, the job will be dropped without notice. When told to raise, the job will be put back and retried. It would also be possible to use `:reschedule` with this lock.

**NOTE** Unless this job is configured with a `lock_timeout: nil` or `lock_timeout: > 0` then all jobs that are attempted to be executed will just be dropped without waiting.

There is an example of this to try it out in the `myapp` application. Run `foreman start` in the root of the directory and open the url: `localhost:5000/work/duplicate_while_executing`.

In the console you should see something like:

```bash
0:32:24 worker.1 | 2017-04-23T08:32:24.955Z 84404 TID-ougq4thko WhileExecutingWorker JID-400ec51c9523f41cd4a35058 INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.956Z 84404 TID-ougq8csew WhileExecutingWorker JID-8d6d9168368eedaed7f75763 INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.957Z 84404 TID-ougq8crt8 WhileExecutingWorker JID-affcd079094c9b26e8b9ba60 INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.959Z 84404 TID-ougq8cs8s WhileExecutingWorker JID-9e197460c067b22eb1b5d07f INFO: start
10:32:24 worker.1 | 2017-04-23T08:32:24.959Z 84404 TID-ougq4thko WhileExecutingWorker JID-400ec51c9523f41cd4a35058 WhileExecutingWorker INFO: perform(1, 2)
10:32:34 worker.1 | 2017-04-23T08:32:34.964Z 84404 TID-ougq4thko WhileExecutingWorker JID-400ec51c9523f41cd4a35058 INFO: done: 10.009 sec
10:32:34 worker.1 | 2017-04-23T08:32:34.965Z 84404 TID-ougq8csew WhileExecutingWorker JID-8d6d9168368eedaed7f75763 WhileExecutingWorker INFO: perform(1, 2)
10:32:44 worker.1 | 2017-04-23T08:32:44.965Z 84404 TID-ougq8crt8 WhileExecutingWorker JID-affcd079094c9b26e8b9ba60 WhileExecutingWorker INFO: perform(1, 2)
10:32:44 worker.1 | 2017-04-23T08:32:44.965Z 84404 TID-ougq8csew WhileExecutingWorker JID-8d6d9168368eedaed7f75763 INFO: done: 20.009 sec
10:32:54 worker.1 | 2017-04-23T08:32:54.970Z 84404 TID-ougq8cs8s WhileExecutingWorker JID-9e197460c067b22eb1b5d07f WhileExecutingWorker INFO: perform(1, 2)
10:32:54 worker.1 | 2017-04-23T08:32:54.969Z 84404 TID-ougq8crt8 WhileExecutingWorker JID-affcd079094c9b26e8b9ba60 INFO: done: 30.012 sec
10:33:04 worker.1 | 2017-04-23T08:33:04.973Z 84404 TID-ougq8cs8s WhileExecutingWorker JID-9e197460c067b22eb1b5d07f INFO: done: 40.014 sec
```

### Custom Locks

You may need to define some custom lock. You can define it in one project folder:

```ruby
# lib/locks/my_custom_lock.rb
module Locks
  class MyCustomLock < SidekiqUniqueJobs::Lock::BaseLock
    def execute
      # Do something ...
    end
  end
end
```

You can refer on all the locks defined in `lib/sidekiq_unique_jobs/lock/*.rb`.

In order to make it available, you should call in your project startup:

(For rails application config/initializers/sidekiq_unique_jobs.rb or other projects, wherever you prefer)

```ruby
SidekiqUniqueJobs.configure do |config|
  config.add_lock :my_custom_lock, Locks::MyCustomLock
end
```

And then you can use it in the jobs definition:

`sidekiq_options lock: :my_custom_lock, on_conflict: :log`

Please not that if you try to override a default lock, an `ArgumentError` will be raised.

## Conflict Strategy

Decides how we handle conflict. We can either `reject` the job to the dead queue or `reschedule` it. Both are useful for jobs that absolutely need to run and have been configured to use the lock `WhileExecuting` that is used only by the sidekiq server process.

Furthermore, `log` can be be used with the lock `UntilExecuted` and `UntilExpired`. Now we write a log entry saying the job could not be pushed because it is a duplicate of another job with the same arguments.

It is possible for locks to have different conflict strategy for the client and server. This is useful for `:until_and_while_executing`.

```ruby
sidekiq_options lock: :until_and_while_executing,
                on_conflict: { client: :log, server: :reject }
```

### log

```ruby
sidekiq_options on_conflict: :log
```

This strategy is intended to be used with `UntilExecuted` and `UntilExpired`. It will log a line that this job is a duplicate of another.

### raise

```ruby
sidekiq_options on_conflict: :raise
```

This strategy is intended to be used with `WhileExecuting`. Basically it will allow us to let the server process crash with a specific error message and be retried without messing up the Sidekiq stats.

### reject

```ruby
sidekiq_options on_conflict: :reject
```

This strategy is intended to be used with `WhileExecuting` and will push the job to the dead queue on conflict.

### replace

```ruby
sidekiq_options on_conflict: :replace
```

This strategy is intended to be used with client locks like `UntilExecuted`.
It will delete any existing job for these arguments from retry, schedule and
queue and retry the lock again.

This is slightly dangerous and should probably only be used for jobs that are
always scheduled in the future. Currently only attempting to retry one time.

### reschedule

```ruby
sidekiq_options on_conflict: :reschedule
```

This strategy is intended to be used with `WhileExecuting` and will delay the job to be tried again in 5 seconds. This will mess up the sidekiq stats but will prevent exceptions from being logged and confuse your sysadmins.

### Custom Strategies

You may need to define some custom strategy. You can define it in one project folder:

```ruby
# lib/strategies/my_custom_strategy.rb
module Strategies
  class MyCustomStrategy < SidekiqUniqueJobs::OnConflict::Strategy
    def call
      # Do something ...
    end
  end
end
```

You can refer to all the strategies defined in `lib/sidekiq_unique_jobs/on_conflict`.

In order to make it available, you should call in your project startup:

(For rails application config/initializers/sidekiq_unique_jobs.rb for other projects, wherever you prefer)

```ruby
SidekiqUniqueJobs.configure do |config|
  config.add_strategy :my_custom_strategy, Strategies::MyCustomStrategy
end
```

And then you can use it in the jobs definition:

```ruby
sidekiq_options lock: :while_executing, on_conflict: :my_custom_strategy
```

Please not that if you try to override a default lock, an `ArgumentError` will be raised.

### 3 Cleanup Dead Locks

For sidekiq versions < 5.1 a `sidekiq_retries_exhausted` block is required per worker class. This is deprecated in Sidekiq 6.0

```ruby
class MyWorker
  sidekiq_retries_exhausted do |msg, _ex|
    digest = msg['lock_digest']
    SidekiqUniqueJobs::Digests.new.delete_by_digest(digest) if digest
  end
end
```

Starting in v5.1, Sidekiq can also fire a global callback when a job dies: In version 7, this is handled automatically for you. You don't need to add a death handler, if you configure v7 like in [Add the middleware](#add-the-middleware) you don't have to worry about the below.

```ruby
Sidekiq.configure_server do |config|
  config.death_handlers << ->(job, _ex) do
    digest = job['lock_digest']
    SidekiqUniqueJobs::Digests.new.delete_by_digest(digest) if digest
  end
end
```

## Debugging

There are several ways of removing keys that are stuck. The prefered way is by using the unique extension to `Sidekiq::Web`. The old console and command line versions still work but might be deprecated in the future. It is better to search for the digest itself and delete the keys matching that digest.

### Sidekiq Web

To use the web extension you need to require it in your routes.

```ruby
#app/config/routes.rb
require 'sidekiq_unique_jobs/web'
mount Sidekiq::Web, at: '/sidekiq'
```

There is no need to `require 'sidekiq/web'` since `sidekiq_unique_jobs/web`
already does this.

To filter/search for keys we can use the wildcard `*`. If we have a unique digest `'uniquejobs:9e9b5ce5d423d3ea470977004b50ff84` we can search for it by enter `*ff84` and it should return all digests that end with `ff84`.

### Reflections (metrics, logging, etc.)

To be able to gather some insights on what is going on inside this gem. I provide a reflection API that can be used.

To setup reflections for logging or metrics, use the following API:

```ruby

def extract_log_from_job(message, job_hash)
  worker    = job_hash['class']
  args      = job_hash['args']
  lock_args = job_hash['lock_args']
  queue     = job_hash['queue']
  {
    message: message,
    worker: worker,
    args: args,
    lock_args: lock_args,
    queue: queue
  }
end

SidekiqUniqueJobs.reflect do |on|
  on.lock_failed do |job_hash|
    message = extract_log_from_job('Lock Failed', job_hash)
    Sidekiq.logger.warn(message)
  end
end
```

#### after_unlock_callback_failed

This is called when you have configured a custom callback for when a lock has been released.

#### error

Not in use yet but will be used deep into the stack to provide a means to catch and report errors inside the gem.

#### execution_failed

When the sidekiq processor picks the job of the queue for certain jobs but your job raised an error to the middleware. This will be the reflection. It is probably nothing to worry about. When your worker raises an error, we need to handle some edge cases for until and while executing.

#### lock_failed

If we can't achieve a lock, this will be the reflection. It most likely is nothing to worry about. We just couldn't retrieve a lock in a timely fashion.

The biggest reason for this reflection would be to gather metrics on which workers fail the most at the locking step for example.

#### locked

For when a lock has been successful. Again, mostly useful for metrics I suppose.

#### reschedule_failed

For when the reschedule strategy failed to reschedule the job.

#### rescheduled

For when a job was successfully rescheduled

#### timeout

This is also mostly useful for reporting/metrics purposes. What this reflection does is signal that the job was configured to wait (`lock_timeout` was configured), but we couldn't retrieve a lock even though we waited for some time.

### unlock_failed

This is not got, this is worth

### unlocked

Also mostly useful for reporting purposes. The job was successfully unlocked.

### unknown_sidekiq_worker

The reason this happens is that the server couldn't find a valid sidekiq worker class. Most likely, that worker isn't intended to be processed by this sidekiq server instance.

#### Show Locks

![Locks](assets/unique_digests_1.png)

#### Show Lock

![Lock](assets/unique_digests_2.png)

## Testing

### Validating Worker Configuration

Since v7 it is possible to perform some simple validation against your workers `sidekiq_options`. What it does is scan for some issues that are known to cause problems in production.

Let's take a _bad_ worker:

```ruby
#app/workers/bad_worker.rb
class BadWorker
  sidekiq_options lock: :while_executing, on_conflict: :replace
end

#spec/workers/bad_worker_spec.rb

require "sidekiq_unique_jobs/testing"
#OR
require "sidekiq_unique_jobs/rspec/matchers"

RSpec.describe BadWorker do
  specify { expect(described_class).to have_valid_sidekiq_options }
end
```

This gives us a helpful error message for a wrongly configured worker:

```bash
Expected BadWorker to have valid sidekiq options but found the following problems:
    on_server_conflict: :replace is incompatible with the server process
```

If you are not using RSpec (a lot of people prefer minitest or test unit) you can do something like:

```ruby
assert_raise(InvalidWorker){ SidekiqUniqueJobs.validate_worker!(BadWorker.get_sidekiq_options) }
```

### Uniqueness

This has been probably the most confusing part of this gem. People get really confused with how unreliable the unique jobs have been. I there for decided to do what Mike is doing for sidekiq enterprise. Read the section about unique jobs: [Enterprise unique jobs][](?)

```ruby
SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
  config.logger_enabled = !Rails.env.test?
end
```

If you truly wanted to test the sidekiq client push you could do something like below. Note that it will only work for the jobs that lock when the client pushes the job to redis (UntilExecuted, UntilAndWhileExecuting and UntilExpired).

```ruby
require "sidekiq_unique_jobs/testing"

RSpec.describe Workers::CoolOne do
  before do
    SidekiqUniqueJobs.config.enabled = false
  end

  # ... your tests that don't test uniqueness

  context 'when Sidekiq::Testing.disabled?' do
    before do
      Sidekiq::Testing.disable!
      Sidekiq.redis(&:flushdb)
    end

    after do
      Sidekiq.redis(&:flushdb)
    end

    it 'prevents duplicate jobs from being scheduled' do
      SidekiqUniqueJobs.use_config(enabled: true) do
        expect(described_class.perform_in(3600, 1)).not_to eq(nil)
        expect(described_class.perform_async(1)).to eq(nil)
      end
    end
  end
end
```

It is recommended to leave the uniqueness testing to the gem maintainers. If you care about how the gem is integration tested have a look at the following specs:

- [spec/sidekiq_unique_jobs/lock/until_and_while_executing_spec.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/sidekiq_unique_jobs/lock/until_and_while_executing_spec.rb)
- [spec/sidekiq_unique_jobs/lock/until_executed_spec.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/sidekiq_unique_jobs/lock/until_executed_spec.rb)
- [spec/sidekiq_unique_jobs/lock/until_expired_spec.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/sidekiq_unique_jobs/lock/until_expired_spec.rb)
- [spec/sidekiq_unique_jobs/lock/while_executing_reject_spec.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/sidekiq_unique_jobs/lock/while_executing_reject_spec.rb)
- [spec/sidekiq_unique_jobs/lock/while_executing_spec.rb](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/spec/sidekiq_unique_jobs/lock/while_executing_spec.rb)

## Configuration

### Other Sidekiq gems

#### apartment-sidekiq

It was reported in [#536](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/536) that the order of the Sidekiq middleware needs to be as follows.

```ruby
Sidekiq.client_middleware do |chain|
  chain.add Apartment::Sidekiq::Middleware::Client
  chain.add SidekiqUniqueJobs::Middleware::Client
end

Sidekiq.server_middleware do |chain|
  chain.add Apartment::Sidekiq::Middleware::Server
  chain.add SidekiqUniqueJobs::Middleware::Server
end
```

The reason being that this gem needs to be configured AFTER the apartment gem or the apartment will not be able to be considered for uniqueness

#### sidekiq-global_id

It was reported in [#235](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/235) that the order of the Sidekiq middleware needs to be as follows.

For a working setup check the following [file](https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/myapp/config/sidekiq.rb#L12).

```ruby
Sidekiq.client_middleware do |chain|
  chain.add Sidekiq::GlobalId::ClientMiddleware
  chain.add SidekiqUniqueJobs::Middleware::Client
end

Sidekiq.server_middleware do |chain|
  chain.add Sidekiq::GlobalId::ServerMiddleware
  chain.add SidekiqUniqueJobs::Middleware::Server
end
```

The reason for this is that the global id needs to be set before the unique jobs middleware runs. Otherwise that won't be available for uniqueness.

#### sidekiq-status

It was reported in [#564](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/564) that the order of the middleware needs to be as follows.

```ruby
# Thanks to @ArturT for the correction

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.minutes
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end


Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.minutes
  end
end
```

The reason for this is that if a job is duplicated it shouldn't end up with the status middleware at all. Status is just a monitor so to prevent clashes, leftovers and ensure cleanup. The status middleware should run after uniqueness on client and before on server. This will lead to less surprises.

### Global Configuration

The gem supports a few different configuration options that might be of interest if you run into some weird issues.

Configure SidekiqUniqueJobs in an initializer or the sidekiq initializer on application startup.

```ruby
SidekiqUniqueJobs.configure do |config|
  config.logger = Sidekiq.logger # default, change at your own discretion
  config.logger_enabled  = true # default, disable for test environments
  config.debug_lua       = false # Turn on when debugging
  config.lock_info       = false # Turn on when debugging
  config.lock_ttl        = 600   # Expire locks after 10 minutes
  config.lock_timeout    = nil   # turn off lock timeout
  config.max_history     = 0     # Turn on when debugging
  config.reaper          = :ruby # :ruby, :lua or :none/nil
  config.reaper_count    = 1000  # Stop reaping after this many keys
  config.reaper_interval = 600   # Reap orphans every 10 minutes
  config.reaper_timeout  = 150   # Timeout reaper after 2.5 minutes
end
```

#### debug_lua

```ruby
SidekiqUniqueJobs.config.debug_lua #=> false
```

Turning on debug_lua will allow the lua scripts to output debug information about what the lua scripts do. It will log all redis commands that are executed and also some helpful messages about what is going on inside the lua script.

#### lock_timeout

```ruby
SidekiqUniqueJobs.config.lock_timeout #=> 0
```

Set a global lock_timeout to use for all jobs that don't otherwise specify a lock_timeout.

Lock timeout decides how long to wait for acquiring the lock. A value of nil means to wait indefinitely for a lock resource to become available.

#### lock_ttl

```ruby
SidekiqUniqueJobs.config.lock_ttl #=> nil
```

Set a global lock_ttl to use for all jobs that don't otherwise specify a lock_ttl.

Lock TTL decides how long to wait at most before considering a lock to be expired and making it possible to reuse that lock.

#### enabled

```ruby
SidekiqUniqueJobs.config.enabled #=> true
```

Globally turn the locking mechanism on or off.

#### logger

```ruby
SidekiqUniqueJobs.config.logger #=> #<Sidekiq::Logger:0x00007fdc1f96d180>
```

By default this gem piggybacks on the Sidekiq logger. It is not recommended to change this as the gem uses some features in the Sidekiq logger and you might run into problems. If you need a different logger and you do run into problems then get in touch and we'll see what we can do about it.

#### max_history

```ruby
SidekiqUniqueJobs.config.max_history #=> 1_000
```

The max_history setting can be used to tweak the number of changelogs generated. It can also be completely turned off if performance suffers or if you are just not interested in using the changelog.

This is a log that can be accessed by a lock to see what happened for that lock. Any items after the configured `max_history` will be automatically deleted as new items are added.

#### reaper

```ruby
SidekiqUniqueJobs.config.reaper #=> :ruby
```

If using the orphans cleanup process it is critical to be aware of the following. The `:ruby` job is much slower but the `:lua` job locks redis while executing. While doing intense processing it is best to avoid locking redis with a lua script. There for the batch size (controlled by the `reaper_count` setting) needs to be reduced.

In my benchmarks deleting 1000 orphaned locks with lua performs around 65% faster than deleting 1000 keys in ruby.

On the other hand if I increase it to 10 000 orphaned locks per cleanup (`reaper_count: 10_0000`) then redis starts throwing:

> BUSY Redis is busy running a script. You can only call SCRIPT KILL or SHUTDOWN NOSAVE. (Redis::CommandError)

If you want to disable the reaper set it to `:none`, `nil` or `false`. Actually, any value that isn't `:ruby` or `:lua` will disable the reaping.

```ruby
SidekiqUniqueJobs.config.reaper = :none
SidekiqUniqueJobs.config.reaper = nil
SidekiqUniqueJobs.config.reaper = false
```

#### reaper_count

```ruby
SidekiqUniqueJobs.config.reaper_count #=> 1_000
```

The reaper_count setting configures how many orphans at a time will be cleaned up by the orphan cleanup job. This might have to be tweaked depending on which orphan job is running.

#### reaper_interval

```ruby
SidekiqUniqueJobs.config.reaper_interval #=> 600
```

The number of seconds between reaping.

#### reaper_timeout

```ruby
SidekiqUniqueJobs.config.reaper_timeout #=> 10
```

The number of seconds to wait for the reaper to finish before raising a TimeoutError. This is done to ensure that the next time we reap isn't getting stuck due to the previous process already running.

#### lock_prefix

```ruby
SidekiqUniqueJobs.config.lock_prefix #=> "uniquejobs"
```

Use if you want a different key prefix for the keys in redis.

### lock_info

```ruby
SidekiqUniqueJobs.config.lock_info #=> false
```

Using lock info will create an additional key for the lock with a json object containing information about the lock. This will be presented in the web interface and might help track down why some jobs are getting stuck.

### Worker Configuration

#### lock_info

Lock info gathers information about a specific lock. It collects things like which `lock_args` where used to compute the `lock_digest` that is used for maintaining uniqueness.

```ruby
sidekiq_options lock_info: false # this is the default, set to true to turn on
```

#### lock_prefix

Use if you want a different key prefix for the keys in redis.

```ruby
sidekiq_options lock_prefix: "uniquejobs" # this is the default value
```

#### lock_ttl

Lock TTL decides how long to wait at most before considering a lock to be expired and making it possible to reuse that lock.

Starting from `v7` the expiration will take place when the job is pushed to the queue.

```ruby
sidekiq_options lock_ttl: nil # default - don't expire keys
sidekiq_options lock_ttl: 20.days.to_i # expire this lock in 20 days
```

#### lock_timeout

This is the timeout (how long to wait) when creating the lock. By default we don't use a timeout so we won't wait for the lock to be created. If you want it is possible to set this like below.

```ruby
sidekiq_options lock_timeout: 0 # default - don't wait at all
sidekiq_options lock_timeout: 5 # wait 5 seconds
sidekiq_options lock_timeout: nil # lock indefinitely, this process won't continue until it gets a lock. VERY DANGEROUS!!
```

#### unique_across_queues

This configuration option is slightly misleading. It doesn't disregard the queue on other jobs. Just on itself, this means that a worker that might schedule jobs into multiple queues will be able to have uniqueness enforced on all queues it is pushed to.

This is mainly intended for `Worker.set(queue: :another).perform_async`.

```ruby
class Worker
  include Sidekiq::Worker

  sidekiq_options unique_across_queues: true, queue: 'default'

  def perform(args); end
end
```

Now if you push override the queue with `Worker.set(queue: 'another').perform_async(1)` it will still be considered unique when compared to `Worker.perform_async(1)` (that was actually pushed to the queue `default`).

#### unique_across_workers

This configuration option is slightly misleading. It doesn't disregard the worker class on other jobs. Just on itself, this means  that the worker class won't be used for generating the unique digest. The only way this option really makes sense is when you want to have uniqueness between two different worker classes.

```ruby
class WorkerOne
  include Sidekiq::Worker

  sidekiq_options unique_across_workers: true, queue: 'default'

  def perform(args); end
end

class WorkerTwo
  include Sidekiq::Worker

  sidekiq_options unique_across_workers: true, queue: 'default'

  def perform(args); end
end


WorkerOne.perform_async(1)
# => 'the jobs unique id'

WorkerTwo.perform_async(1)
# => nil because WorkerOne just stole the lock
```

### Finer Control over Uniqueness

Sometimes it is desired to have a finer control over which arguments are used in determining uniqueness of the job, and others may be _transient_. For this use-case, you need to define either a `lock_args` method, or a ruby proc.

*NOTE:* The lock_args method need to return an array of values to use for uniqueness check.

*NOTE:* The arguments passed to the proc or the method is always an array. If your method takes a single array as argument the value of args will be `[[...]]`.

The method or the proc can return a modified version of args without the transient arguments included, as shown below:

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options lock: :until_and_while_executing,
                  lock_args_method: :lock_args # this is default and will be used if such a method is defined

  def self.lock_args(args)
    [ args[0], args[2][:type] ]
  end

  ...

end

class UniqueJobWithFilterProc
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed,
                  lock_args_method: ->(args) { [ args.first ] }

  ...

end
```

It is possible to ensure different types of unique args based on context. I can't vouch for the below example but see [#203](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/203) for the discussion.

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options lock: :until_and_while_executing, lock_args_method: :lock_args

  def self.lock_args(args)
    if Sidekiq::ProcessSet.new.size > 1
      # sidekiq runtime; uniqueness for the object (first arg)
      args.first
    else
      # queuing from the app; uniqueness for all params
      args
    end
  end
end
```

### After Unlock Callback

If you need to perform any additional work after the lock has been released you can provide an `#after_unlock` instance method. The method will be called when the lock has been unlocked. Most times this means after yield but there are two exceptions to that.

**Exception 1:** UntilExecuting unlocks and uses callback before yielding.
**Exception 2:** UntilExpired expires eventually, no after_unlock hook is called.

**NOTE:** _It is also possible to write this code as a class method._

```ruby
class UniqueJobWithFilterMethod
  include Sidekiq::Worker
  sidekiq_options lock: :while_executing,

  def self.after_unlock
   # block has yielded and lock is released
  end

  def after_unlock
   # block has yielded and lock is released
  end
  ...
end.
```

## Communication

There is a [![Join the chat at https://gitter.im/mhenrixon/sidekiq-unique-jobs](https://badges.gitter.im/mhenrixon/sidekiq-unique-jobs.svg)](https://gitter.im/mhenrixon/sidekiq-unique-jobs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) for praise or scorn. This would be a good place to have lengthy discuss or brilliant suggestions or simply just nudge me if I forget about anything.

## Contributing

1. Fork it
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create new Pull Request

## Contributors

You can find a list of contributors over on [Contributors][]

[Enterprise unique jobs]: https://github.com/mperham/sidekiq/wiki/Ent-Unique-Jobs
[Contributors]: https://github.com/mhenrixon/sidekiq-unique-jobs/graphs/contributors
[v4.0.18]: https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.18
[v5.0.10]: https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10.
[Sidekiq requirements]: https://github.com/mperham/sidekiq#requirements
