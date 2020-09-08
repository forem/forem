class AddSubscriberEmailIndexToUserSubscriptions < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    if index_exists?(:user_subscriptions, %i[subscriber_id user_subscription_sourceable_id user_subscription_sourceable_type])
      remove_index :user_subscriptions,
                   column: %i[subscriber_id user_subscription_sourceable_id user_subscription_sourceable_type],
                   algorithm: :concurrently
    end

    unless index_exists?(:user_subscriptions, :subscriber_email)
      add_index :user_subscriptions,
                :subscriber_email,
                algorithm: :concurrently
    end

    unless index_exists?(:user_subscriptions, %i[subscriber_id subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id])
      add_index :user_subscriptions,
                %i[subscriber_id subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id],
                name: "index_subscriber_id_and_email_with_user_subscription_source",
                unique: true,
                algorithm: :concurrently
    end
  end

  def down
    unless index_exists?(:user_subscriptions, %i[subscriber_id user_subscription_sourceable_id user_subscription_sourceable_type])
      add_index :user_subscriptions,
                %i[subscriber_id user_subscription_sourceable_id user_subscription_sourceable_type],
                unique: true,
                name: :index_on_subscriber_id_user_subscription_sourceable_type_and_id,
                algorithm: :concurrently
    end

    if index_exists?(:user_subscriptions, :subscriber_email)
      remove_index :user_subscriptions, column: :subscriber_email, algorithm: :concurrently
    end

    if index_exists?(:user_subscriptions, %i[subscriber_id subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id])
      remove_index :user_subscriptions,
                   column: %i[subscriber_id subscriber_email user_subscription_sourceable_type user_subscription_sourceable_id],
                   algorithm: :concurrently
    end
  end
end
