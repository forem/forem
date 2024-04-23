class Badge < ApplicationRecord
  mount_uploader :badge_image, BadgeUploader
  resourcify

  has_many :badge_achievements, dependent: :restrict_with_error
  has_many :tags, dependent: :restrict_with_error
  has_many :users, through: :badge_achievements

  validates :badge_image, presence: true
  validates :description, presence: true
  validates :slug, presence: true
  validates :title, presence: true, uniqueness: true
  validates :allow_multiple_awards, inclusion: { in: [true, false] }

  before_validation :generate_slug

  def self.id_for_slug(slug)
    select(:id).find_by(slug: slug)&.id
  end

  def path
    "/badge/#{slug}"
  end

  private

  def generate_slug
    self.slug = CGI.escape(title.to_s).parameterize
  end
end
