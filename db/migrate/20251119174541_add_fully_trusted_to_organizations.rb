class AddFullyTrustedToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :fully_trusted, :boolean, default: false, null: false
  end
end
