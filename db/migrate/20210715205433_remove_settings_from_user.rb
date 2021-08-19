class RemoveSettingsFromUser < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      # general user settings
      remove_column :users, :config_theme, :string
      remove_column :users, :config_font, :string
      remove_column :users, :config_navbar, :string
      remove_column :users, :display_announcements, :boolean
      remove_column :users, :display_sponsors, :boolean
      remove_column :users, :editor_version, :string
      remove_column :users, :experience_level, :integer
      remove_column :users, :feed_mark_canonical, :boolean
      remove_column :users, :feed_referential_link, :boolean
      remove_column :users, :feed_url, :string
      remove_column :users, :inbox_guidelines, :string
      remove_column :users, :inbox_type, :string
      remove_column :users, :permit_adjacent_sponsors, :boolean

      # notification user settings
      remove_column :users, :email_badge_notifications, :boolean
      remove_column :users, :email_comment_notifications, :boolean
      remove_column :users, :email_community_mod_newsletter, :boolean
      remove_column :users, :email_connect_messages, :boolean
      remove_column :users, :email_digest_periodic, :boolean
      remove_column :users, :email_follower_notifications, :boolean
      remove_column :users, :email_membership_newsletter, :boolean
      remove_column :users, :email_mention_notifications, :boolean
      remove_column :users, :email_newsletter, :boolean
      remove_column :users, :email_tag_mod_newsletter, :boolean
      remove_column :users, :email_unread_notifications, :boolean
      remove_column :users, :mobile_comment_notifications, :boolean
      remove_column :users, :mod_roundrobin_notifications, :boolean
      remove_column :users, :reaction_notifications, :boolean
      remove_column :users, :welcome_notifications, :boolean
    end
  end
end
