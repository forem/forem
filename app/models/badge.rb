class Badge < ApplicationRecord
  mount_uploader :badge_image, BadgeUploader

  has_many :badge_achievements
  has_many :tags
  has_many :users, through: :badge_achievements

  validates :badge_image, presence: true
  validates :description, presence: true
  validates :title, presence: true, uniqueness: true

  before_validation :generate_slug
  after_save :bust_path

  def path
    "/badge/#{slug}"
  end

  private

  def generate_slug
    self.slug = CGI.escape(title.to_s).parameterize
  end

  def bust_path
    CacheBuster.bust(path)
    CacheBuster.bust("#{path}?i=i")
  end
end
