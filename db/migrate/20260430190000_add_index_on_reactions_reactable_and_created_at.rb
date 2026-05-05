class AddIndexOnReactionsReactableAndCreatedAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Speeds up date-bounded analytics queries that join on
  # (reactable_id, reactable_type) and then filter by created_at,
  # specifically AnalyticsService#calculate_reactions_stats_per_day
  # and the bundled /api/analytics/dashboard endpoint.
  def up
    safety_assured do
      db_user = connection.query_value("SELECT current_user")
      begin
        execute "ALTER ROLE #{db_user} SET statement_timeout = 0;"
        execute "SET statement_timeout = 0;"

        # Drop in case a previous deploy timed out and left an invalid index
        remove_index :reactions, name: "index_reactions_on_reactable_and_created_at", if_exists: true, algorithm: :concurrently

        add_index :reactions,
                  %i[reactable_id reactable_type created_at],
                  name: "index_reactions_on_reactable_and_created_at",
                  algorithm: :concurrently
      ensure
        execute "ALTER ROLE #{db_user} RESET statement_timeout;"
      end
    end
  end

  def down
    remove_index :reactions, name: "index_reactions_on_reactable_and_created_at", if_exists: true, algorithm: :concurrently
  end
end
