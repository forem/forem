class AddUserIdToPages < ActiveRecord::Migration[8.0]
  def up
    add_column :pages, :user_id, :bigint
    add_foreign_key :pages, :users, on_delete: :cascade, validate: false
  end

  def down
    safety_assured do
      remove_foreign_key :pages, :users
      remove_column :pages, :user_id, :bigint
    end
  end
end
