class Podcast < ApplicationRecord
  resourcify

  has_many :podcast_episodes
  belongs_to :creator, class_name: "User", inverse_of: :created_podcasts, foreign_key: :creator_id, optional: true

  mount_uploader :image, ProfileImageUploader
  mount_uploader :pattern_image, ProfileImageUploader

  validates :main_color_hex, :title, :feed_url, :image, presence: true
  validates :main_color_hex, format: /\A([a-fA-F]|[0-9]){6}\Z/
  validates :feed_url, uniqueness: true, url: { schemes: %w[https http] }
  validates :slug,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-zA-Z0-9\-_]+\Z/ },
            exclusion: { in: ReservedWords.all, message: "slug is reserved" }
  validate :unique_slug_including_users_and_orgs, if: :slug_changed?

  after_save :bust_cache

  scope :reachable, -> { where(id: PodcastEpisode.reachable.select(:podcast_id)) }
  scope :published, -> { where(published: true) }
  scope :available, -> { reachable.published }

  alias_attribute :path, :slug
  alias_attribute :profile_image_url, :image_url
  alias_attribute :name, :title

  def existing_episode(item)
    episode = PodcastEpisode.where(media_url: item.enclosure_url).
      or(PodcastEpisode.where(title: item.title)).
      or(PodcastEpisode.where(guid: item.guid.to_s)).presence
    episode ||= PodcastEpisode.where(website_url: item.link).presence if unique_website_url?
    episode.to_a.first
  end

  def admins
    User.with_role(:podcast_admin, self)
  end

  def image_90
    ProfileImage.new(self).get(width: 90)
  end

  private

  def unique_slug_including_users_and_orgs
    slug_exists = User.exists?(username: slug) || Organization.exists?(slug: slug) || Page.exists?(slug: slug)
    errors.add(:slug, "is taken.") if slug_exists
  end

  def bust_cache
    return unless path

    Podcasts::BustCacheWorker.perform_async(path)
  end
end
