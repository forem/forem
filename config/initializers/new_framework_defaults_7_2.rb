# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.2 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `7.2`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

# Controls whether Active Job's `#perform_later` and similar methods automatically defer
# the job queuing to after the current Active Record transaction is committed.
Rails.application.config.active_job.enqueue_after_transaction_commit = :default

# Adds image/webp to the list of content types Active Storage considers as an image.
# Guarded with respond_to? since Active Storage is not loaded in Forem.
if Rails.application.config.respond_to?(:active_storage)
  Rails.application.config.active_storage.web_image_content_types = %w[image/png image/jpeg image/gif image/webp]
end

# Enable validation of migration timestamps. When set, an ActiveRecord::InvalidMigrationTimestampError
# will be raised if the timestamp prefix for a migration is more than a day ahead of the timestamp
# associated with the current time.
Rails.application.config.active_record.validate_migration_timestamps = true

# Controls whether the PostgresqlAdapter should decode dates automatically with manual queries.
Rails.application.config.active_record.postgresql_adapter_decode_dates = true

# Enables YJIT as of Ruby 3.3, to bring sizeable performance improvements. If you are
# deploying to a memory constrained environment you may want to set this to `false`.
# Guarded because config.yjit is only introduced in Rails 7.2.
if Rails.application.config.respond_to?(:yjit)
  Rails.application.config.yjit = true
end
