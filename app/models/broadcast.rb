class Broadcast < ApplicationRecord
  resourcify

  has_many :notifications, as: :notifiable, inverse_of: :notifiable

  validates :title, :type_of, :processed_html, presence: true
  # TODO: [@thepracticaldev/delightful] Remove Onboarding type once we have launched welcome notifications.
  validates :type_of, inclusion: { in: %w[Announcement Onboarding Welcome] }

  scope :active, -> { where(active: true) }

  def get_inner_body(content)
    Nokogiri::HTML(content).at("body").inner_html
  end
end
