class AddConfirmationTokenToEmailAuthorization < ActiveRecord::Migration[5.2]
  def change
    add_column :email_authorizations, :confirmation_token, :string
  end
end
