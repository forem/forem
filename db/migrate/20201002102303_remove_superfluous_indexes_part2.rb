class RemoveSuperfluousIndexesPart2 < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    # covered by index_subscriber_id_and_email_with_user_subscription_source
    if index_exists?(:user_subscriptions, :subscriber_id)
      remove_index :user_subscriptions, column: :subscriber_id, algorithm: :concurrently
    end

    # covered by index_badge_achievements_on_badge_id_and_user_id
    if index_exists?(:badge_achievements, :badge_id)
      remove_index :badge_achievements, column: :badge_id, algorithm: :concurrently
    end

    # covered by index_badge_achievements_on_user_id_and_badge_id
    if index_exists?(:badge_achievements, :user_id)
      remove_index :badge_achievements, column: :user_id, algorithm: :concurrently
    end

    # covered by index_chat_channel_memberships_on_chat_channel_id_and_user_id
    if index_exists?(:chat_channel_memberships, :chat_channel_id)
      remove_index :chat_channel_memberships, column: :chat_channel_id, algorithm: :concurrently
    end

    # covered by index_chat_channel_memberships_on_user_id_and_chat_channel_id
    if index_exists?(:chat_channel_memberships, :user_id)
      remove_index :chat_channel_memberships, column: :user_id, algorithm: :concurrently
    end

    # covered by index_response_templates_on_user_id_and_type_of
    if index_exists?(:response_templates, :user_id)
      remove_index :response_templates, column: :user_id, algorithm: :concurrently
    end
  end

  def down
    unless index_exists?(:user_subscriptions, :subscriber_id)
      add_index :user_subscriptions, :subscriber_id, algorithm: :concurrently
    end

    unless index_exists?(:badge_achievements, :badge_id)
      add_index :badge_achievements, :badge_id, algorithm: :concurrently
    end

    unless index_exists?(:badge_achievements, :user_id)
      add_index :badge_achievements, :user_id, algorithm: :concurrently
    end

    unless index_exists?(:chat_channel_memberships, :chat_channel_id)
      add_index :chat_channel_memberships, :chat_channel_id, algorithm: :concurrently
    end

    unless index_exists?(:chat_channel_memberships, :user_id)
      add_index :chat_channel_memberships, :user_id, algorithm: :concurrently
    end

    unless index_exists?(:response_templates, :user_id)
      add_index :response_templates, :user_id, algorithm: :concurrently
    end
  end
end
