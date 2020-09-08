class AddSubscriberEmailToUserSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :user_subscriptions, :subscriber_email, :string, null: false
  end
end
