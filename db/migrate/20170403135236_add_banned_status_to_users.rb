class AddBannedStatusToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :banned, :boolean, default: false
    add_column :articles, :removed_for_abuse, :boolean, default: false
    add_column :articles, :abuse_removal_reason, :string
  end
end
