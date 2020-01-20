class AddOrganizationInfoUpdatedAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :organization_info_updated_at, :datetime
  end
end
