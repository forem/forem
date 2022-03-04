class RemoveUnusedColumnsFromOrganizations < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :organizations, :address, :string
      remove_column :organizations, :approved, :boolean, default: false
      remove_column :organizations, :city, :string
      remove_column :organizations, :country, :string
      remove_column :organizations, :jobs_email, :string
      remove_column :organizations, :jobs_url, :string
      remove_column :organizations, :state, :string
      remove_column :organizations, :zip_code, :string
    end
  end
end
