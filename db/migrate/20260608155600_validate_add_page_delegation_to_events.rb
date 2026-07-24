class ValidateAddPageDelegationToEvents < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :events, :pages
  end
end
