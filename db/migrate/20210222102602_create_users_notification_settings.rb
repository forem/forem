class CreateUsersNotificationSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :users_notification_settings do |t|
      t.integer :user_id, null: false
      t.boolean "email_badge_notifications", default: true
      t.boolean "email_comment_notifications", default: true
      t.boolean "email_community_mod_newsletter", default: false
      t.boolean "email_connect_messages", default: true
      t.boolean "email_digest_periodic", default: false, null: false
      t.boolean "email_follower_notifications", default: true
      t.boolean "email_membership_newsletter", default: false
      t.boolean "email_mention_notifications", default: true
      t.boolean "email_newsletter", default: false
      t.boolean "email_tag_mod_newsletter", default: false
      t.boolean "email_unread_notifications", default: true
      t.boolean "mobile_comment_notifications", default: true
      t.boolean "mod_roundrobin_notifications", default: true
      t.boolean "reaction_notifications", default: true
      t.boolean "welcome_notifications", default: true, null: false

      t.timestamps
    end
  end
end
