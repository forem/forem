class ValidateCreateEmailAuthorizationTable < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key :email_authorizations, :users
  end
end
