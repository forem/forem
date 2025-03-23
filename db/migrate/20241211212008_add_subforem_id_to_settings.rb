class AddSubforemIdToSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :settings_authentications, :subforem_id, :bigint
    add_column :settings_campaigns, :subforem_id, :bigint
    add_column :settings_communities, :subforem_id, :bigint
    add_column :settings_rate_limits, :subforem_id, :bigint
    add_column :settings_smtp, :subforem_id, :bigint
    add_column :settings_user_experiences, :subforem_id, :bigint
    add_column :site_configs, :subforem_id, :bigint
  end
end
