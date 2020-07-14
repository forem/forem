class WelcomeNotification < ApplicationRecord
  has_one :broadcast, as: :broadcastable
  has_many :notifications, as: :notifiable, inverse_of: :notifiable

  validates :cta_text, :cta_url, :headline, presence: true
  validates :secondary_cta_text, :secondary_cta_url, optional: true
end
