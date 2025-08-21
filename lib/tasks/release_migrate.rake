namespace :release do
  desc "Run migrations on every release"
  task migrate_if_pending: :environment do
    puts "[release] ⏳ Running `db:migrate` on every release…"
    # Invoke the normal Rails migrations. Because we are invoking a Rake task,
    # it will obtain the advisory lock, run only the pending migrations, then release.
    Rake::Task["db:migrate"].invoke
    puts "[release] ✅ Migrations completed."
  end
end
