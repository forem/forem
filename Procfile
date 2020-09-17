release: ./release-tasks.sh
web: bin/start-pgbouncer bundle exec puma -C config/puma.rb
sidekiq_worker: bundle exec sidekiq -t 25
