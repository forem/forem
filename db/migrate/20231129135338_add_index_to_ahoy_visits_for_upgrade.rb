class AddIndexToAhoyVisitsForUpgrade < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :ahoy_visits, [:visitor_token, :started_at], algorithm: :concurrently
  end
end
