# check pending migrations in development, only when console, runner and server
# are executed
if Rails.env.development? && %w[c console runner s server].include?(ENV["COMMAND"])
  # check pending schema migrations
  ActiveRecord::Migration.check_pending!

  # check pending data migrations
  if RailsDataMigrations::Migrator.list_pending_migrations.any?
    message = <<~PENDING
      You have pending data migrations. Please run 'rails data:migrate'".
      You can also check which data migrations are pending by running 'rails data:migrate:pending'.
    PENDING

    raise PendingDataMigrationError, message
  end
end
