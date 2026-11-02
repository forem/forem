# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers_count = ENV.fetch("WEB_CONCURRENCY", 2).to_i
workers workers_count

# Route incoming requests to idle workers before busy workers to prevent
# head-of-line queueing behind cold or GC-paused workers.
if workers_count > 1
  wait_for_less_busy_worker ENV.fetch("PUMA_WAIT_FOR_LESS_BUSY_WORKER", 0.005).to_f
end

# Give workers 25s to drain on shutdown so Puma exits cleanly before
# Heroku's 30s R12 SIGKILL deadline.
worker_shutdown_timeout ENV.fetch("PUMA_WORKER_SHUTDOWN_TIMEOUT", 25).to_i

# calls GC a handful of times and compacts the heap on Ruby 2.7+ before forking.
# This may reduce memory usage of Puma on MRI.
nakayoshi_fork

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

before_fork do
  ServerWarmup.before_fork if defined?(ServerWarmup)
end

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  if defined?(ServerWarmup)
    ServerWarmup.on_worker_boot
  else
    ActiveRecord::Base.establish_connection
  end
end

on_worker_shutdown do
  ServerWarmup.on_worker_shutdown if defined?(ServerWarmup)
end
