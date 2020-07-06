class WelcomeNotification < ApplicationRecord
  belongs_to :broadcastable, polymorphic: true
  has_many :notifications, as: :notifiable, inverse_of: :notifiable
end
