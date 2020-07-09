class AddSubscribedToUserSubscriptionsCountToUsers < ActiveRecord::Migration[6.0]
  def self.up
    add_column :users, :subscribed_to_user_subscriptions_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :users, :subscribed_to_user_subscriptions_count
  end
end
