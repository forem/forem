class AddOldUsernamesToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :old_slug, :string
    add_column :organizations, :old_old_slug, :string
  end
end
