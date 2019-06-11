class Podcast < ApplicationRecord
  has_many :podcast_episodes

  mount_uploader :image, ProfileImageUploader
  mount_uploader :pattern_image, ProfileImageUploader

  validates :main_color_hex, :title, :feed_url, :image, :slug, presence: true
  validates :feed_url, :slug, uniqueness: true

  after_save :bust_cache
  after_create :pull_all_episodes

  alias_attribute :path, :slug
  alias_attribute :profile_image_url, :image_url
  alias_attribute :name, :title

  private

  def bust_cache
    return unless path

    CacheBuster.new.bust("/" + path)
  end

  def pull_all_episodes
    Podcasts::GetEpisodesJob.perform_later(id)
  end

  def pull_all_episodes_without_delay
    Podcasts::GetEpisodesJob.perform_now(id)
  end
end
