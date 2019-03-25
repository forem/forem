class ChangeUsernameToNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null :users, :username, false
  end
end
