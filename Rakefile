# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

Rails.application.load_tasks

# Use strong_migrations to alphabetize schema columns
task "db:schema:dump": "strong_migrations:alphabetize_columns"
