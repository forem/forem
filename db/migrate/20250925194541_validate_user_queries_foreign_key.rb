class ValidateUserQueriesForeignKey < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :user_queries, :users
  end
end
