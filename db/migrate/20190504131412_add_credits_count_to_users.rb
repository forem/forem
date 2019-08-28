class AddCreditsCountToUsers < ActiveRecord::Migration[5.2]
  def self.up
    add_column :users, :credits_count, :integer, null: false, default: 0
    add_column :users, :spent_credits_count, :integer, null: false, default: 0
    add_column :users, :unspent_credits_count, :integer, null: false, default: 0
    add_column :organizations, :credits_count, :integer, null: false, default: 0
    add_column :organizations, :spent_credits_count, :integer, null: false, default: 0
    add_column :organizations, :unspent_credits_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :users, :credits_count
    remove_column :users, :spent_credits_count
    remove_column :users, :unspent_credits_count
    remove_column :users, :credits_count
    remove_column :users, :spent_credits_count
    remove_column :users, :unspent_credits_count
  end
end
