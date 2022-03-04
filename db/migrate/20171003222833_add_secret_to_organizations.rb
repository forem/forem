class AddSecretToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :secret, :string
  end
end
