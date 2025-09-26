namespace :release do
  desc "Run migrations only if there are pending migrations (acquires advisory lock only when needed)"
  task migrate_if_pending: :environment do
    Rake::Task["db:migrate"].invoke
  end
end