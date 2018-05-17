class Badge < ApplicationRecord
  mount_uploader :badge_image, BadgeUploader

  has_many :badge_achievements
  has_many :users, through: :badge_achievements

  validates :title, presence: true, uniqueness: true
  validates :description, presence: true
  validates :badge_image, presence: true

  before_validation :generate_slug
  private

  def generate_slug
    self.slug = title.to_s.downcase.tr(" ", "-").gsub(/[^\w-]/, "").tr("_", "")
  end
end
