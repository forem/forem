class ValidateEventIdOnPages < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :pages, :events
  end
end
