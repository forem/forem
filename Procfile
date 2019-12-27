release: STATEMENT_TIMEOUT=180000 bundle exec rails db:migrate
web: bin/start-pgbouncer bundle exec puma -C config/puma.rb
worker: bundle exec rails jobs:work
sidekiq_worker: bundle exec sidekiq -t 25
