class RemoveUserOrganizationId < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :users, :organization_id, :integer }
  end
end
