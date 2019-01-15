class AddOpenInboxToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :open_inbox, :boolean, default: false
  end
end
