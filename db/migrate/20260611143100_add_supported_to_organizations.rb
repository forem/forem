class AddSupportedToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :supported, :boolean, default: false, null: false
  end
end
