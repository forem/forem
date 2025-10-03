class AddUserQueryForeignKeyToEmails < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :emails, :user_queries, validate: false
  end
end
