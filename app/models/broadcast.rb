class Broadcast < ApplicationRecord
  has_many :notifications, as: :notifiable, inverse_of: :notifiable

  validates :title, :type_of, :processed_html, presence: true
  validates :type_of, inclusion: { in: %w[Announcement Onboarding] }

  def get_inner_body(content)
    Nokogiri::HTML(content).at("body").inner_html
  end
end
