class AddCtaTextAndCtaUrlToWelcomeNotifications < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      change_table :welcome_notifications, bulk: true do |t|
        t.string :cta_text
        t.string :cta_url
        t.string :secondary_cta_text
        t.string :secondary_cta_url
      end
    end
  end
end
