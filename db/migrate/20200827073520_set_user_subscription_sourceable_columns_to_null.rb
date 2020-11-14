class SetUserSubscriptionSourceableColumnsToNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :user_subscriptions, :user_subscription_sourceable_id, true
    change_column_null :user_subscriptions, :user_subscription_sourceable_type, true
  end
end
