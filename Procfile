release: bundle exec rails db:migrate
web: bin/start-pgbouncer bundle exec puma -C config/puma.rb
worker: bundle exec rails jobs:work
