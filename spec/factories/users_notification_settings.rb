FactoryBot.define do
  factory :users_notification_setting, class: "Users::NotificationSetting" do
    email_badge_notifications { true }
    email_comment_notifications { true }
    email_community_mod_newsletter { false }
    email_connect_messages { true }
    email_digest_periodic { false }
    email_follower_notifications { true }
    email_membership_newsletter { false }
    email_mention_notifications { true }
    email_newsletter { false }
    email_tag_mod_newsletter { false }
    email_unread_notifications { true }
    mobile_comment_notifications { true }
    mod_roundrobin_notifications { true }
    reaction_notifications { true }
    welcome_notifications { true }
  end
end
