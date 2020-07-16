class WelcomeNotification < ApplicationRecord
  has_one :broadcast, as: :broadcastable
  has_many :notifications, as: :notifiable, inverse_of: :notifiable
end
