# Rails 6 has ActiveSupport::ActionableError which would allow us to tell the
# user how to solve this inline, but we don't have it yet
# see <https://github.com/rails/rails/blob/fc895aa867beb3c39ea87e28813410d21b826c78/activerecord/lib/active_record/migration.rb#L132>

class PendingDataMigrationError < StandardError
end
