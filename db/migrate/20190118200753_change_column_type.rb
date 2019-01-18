class ChangeColumnType < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :inbox, :string, default: "private"
  end
end
