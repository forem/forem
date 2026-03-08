class AddVerificationStatusToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :verification_status, :string
    add_column :organizations, :verification_error, :string
  end
end
