class DropUserTitleFromOrganizationMemberships < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :organization_memberships, :user_title, :string
    end
  end
end
