class Podcast < ApplicationRecord
  has_many :podcast_episodes

  mount_uploader :image, ProfileImageUploader
  mount_uploader :pattern_image, ProfileImageUploader

  validates :main_color_hex, presence: true

  after_save :bust_cache

  def path
    slug
  end

  def profile_image_url
    image_url
  end

  def name
    title
  end

  private

  def bust_cache
    CacheBuster.new.bust("/" + path)
  end
end
