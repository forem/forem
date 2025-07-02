class AddSubForemIndexes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :settings_authentications, :subforem_id, algorithm: :concurrently
    add_index :settings_campaigns, :subforem_id, algorithm: :concurrently
    add_index :settings_communities, :subforem_id, algorithm: :concurrently
    add_index :settings_rate_limits, :subforem_id, algorithm: :concurrently
    add_index :settings_smtp, :subforem_id, algorithm: :concurrently
    add_index :settings_user_experiences, :subforem_id, algorithm: :concurrently
    add_index :site_configs, :subforem_id, algorithm: :concurrently
  end
end
