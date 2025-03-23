class UpdateUniqueIndexOnSettings < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    # Update unique index for settings_authentications
    remove_index :settings_authentications, :var, name: "index_settings_authentications_on_var", algorithm: :concurrently
    add_index :settings_authentications, [:var, :subforem_id], unique: true, name: "index_settings_authentications_on_var_and_subforem_id", algorithm: :concurrently

    # Update unique index for settings_campaigns
    remove_index :settings_campaigns, :var, name: "index_settings_campaigns_on_var", algorithm: :concurrently
    add_index :settings_campaigns, [:var, :subforem_id], unique: true, name: "index_settings_campaigns_on_var_and_subforem_id", algorithm: :concurrently

    # Update unique index for settings_communities
    remove_index :settings_communities, :var, name: "index_settings_communities_on_var", algorithm: :concurrently
    add_index :settings_communities, [:var, :subforem_id], unique: true, name: "index_settings_communities_on_var_and_subforem_id", algorithm: :concurrently

    # Update unique index for settings_rate_limits
    remove_index :settings_rate_limits, :var, name: "index_settings_rate_limits_on_var", algorithm: :concurrently
    add_index :settings_rate_limits, [:var, :subforem_id], unique: true, name: "index_settings_rate_limits_on_var_and_subforem_id", algorithm: :concurrently

    # Update unique index for settings_smtp
    remove_index :settings_smtp, :var, name: "index_settings_smtp_on_var", algorithm: :concurrently
    add_index :settings_smtp, [:var, :subforem_id], unique: true, name: "index_settings_smtp_on_var_and_subforem_id", algorithm: :concurrently

    # Update unique index for settings_user_experiences
    remove_index :settings_user_experiences, :var, name: "index_settings_user_experiences_on_var", algorithm: :concurrently
    add_index :settings_user_experiences, [:var, :subforem_id], unique: true, name: "index_settings_user_experiences_on_var_and_subforem_id", algorithm: :concurrently

    # Update unique index for site_configs
    remove_index :site_configs, :var, name: "index_site_configs_on_var", algorithm: :concurrently
    add_index :site_configs, [:var, :subforem_id], unique: true, name: "index_site_configs_on_var_and_subforem_id", algorithm: :concurrently
  end
end
