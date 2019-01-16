workers Integer(ENV["WEB_CONCURRENCY"] || 2)
threads_count = Integer(ENV["MAX_THREADS"] || 5)
threads threads_count, threads_count

worker_timeout 15
worker_shutdown_timeout 8

preload_app!

rackup DefaultRackup
port ENV["PORT"] || 3000
environment ENV["RACK_ENV"] || "development"

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
