class AddInboxToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :inbox, :string, default: "private"
  end
end
