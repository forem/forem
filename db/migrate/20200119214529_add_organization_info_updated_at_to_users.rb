class AddOrganizationInfoUpdatedAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :organization_info_updated_at, :datetime, default: "2017-01-01 05:00:00"
  end
end
