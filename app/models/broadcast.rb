class Broadcast < ApplicationRecord
  resourcify

  belongs_to :broadcastable, polymorphic: true
  belongs_to :announcement, class_name: "Announcement", optional: true
  belongs_to :welcome_notification, class_name: "WelcomeNotification", optional: true

  validates :title, uniqueness: { scope: :type_of }, presence: true
  validates :type_of, :processed_html, :broadcastable_type, :broadcastable_id, presence: true
  validates :type_of, inclusion: { in: %w[Announcement Welcome] }

  before_save :update_active_status_updated_at, if: :will_save_change_to_active?

  scope :active, -> { where(active: true) }
  scope :announcement, -> { where(type_of: "Announcement") }
  scope :welcome, -> { where(type_of: "Welcome") }

  def get_inner_body(content)
    Nokogiri::HTML(content).at("body").inner_html
  end

  private

  def update_active_status_updated_at
    self.active_status_updated_at = Time.current
  end
end
