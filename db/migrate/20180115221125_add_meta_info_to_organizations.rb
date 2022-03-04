class AddMetaInfoToOrganizations < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :email, :string
    add_column :organizations, :location, :string
    add_column :organizations, :company_size, :string
    add_column :organizations, :tech_stack, :string
    add_column :organizations, :story, :string
  end
end
