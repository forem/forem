class ValidateUserIdOnPages < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :pages, :users
  end
end
