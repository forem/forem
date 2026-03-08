class AddVerificationToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :verified, :boolean, default: false, null: false
    add_column :organizations, :verified_at, :datetime
    add_column :organizations, :verification_url, :string
  end
end
