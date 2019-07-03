class Badge < ApplicationRecord
  mount_uploader :badge_image, BadgeUploader

  has_many :badge_achievements
  has_many :tags
  has_many :users, through: :badge_achievements

  validates :title, presence: true, uniqueness: true
  validates :description, presence: true
  validates :badge_image, presence: true

  before_validation :generate_slug
  after_save :bust_path

  def path
    "/badge/#{slug}"
  end

  private

  def generate_slug
    self.slug = title.to_s.parameterize
  end

  def bust_path
    cache_buster = CacheBuster.new
    cache_buster.bust path
    cache_buster.bust path + "?i=i"
  end
end
