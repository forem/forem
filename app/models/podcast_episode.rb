class PodcastEpisode < ApplicationRecord
  include PgSearch::Model

  acts_as_taggable

  delegate :slug, to: :podcast, prefix: true
  delegate :image_url, to: :podcast, prefix: true
  delegate :title, to: :podcast, prefix: true
  delegate :published, to: :podcast

  belongs_to :podcast
  has_many :comments, as: :commentable, inverse_of: :commentable, dependent: :nullify
  has_many :podcast_episode_appearances, dependent: :destroy
  has_many :users, through: :podcast_episode_appearances

  mount_uploader :image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :comments_count, presence: true
  validates :guid, presence: true, uniqueness: true
  validates :media_url, presence: true, uniqueness: true
  validates :reactions_count, presence: true
  validates :slug, presence: true
  validates :title, presence: true

  before_validation :process_html_and_prefix_all_images
  # NOTE: Any create callbacks will not be run since we use activerecord-import to create episodes
  # https://github.com/zdennis/activerecord-import#callbacks
  after_update :purge
  after_destroy :purge, :purge_all
  after_save :bust_cache

  pg_search_scope :search_podcast_episodes,
                  against: %i[body subtitle title],
                  using: { tsearch: { prefix: true } }

  scope :reachable, -> { where(reachable: true) }
  scope :published, -> { joins(:podcast).where(podcasts: { published: true }) }
  scope :available, -> { reachable.published }
  scope :for_user, lambda { |user|
    joins(:podcast).where(podcasts: { creator_id: user.id })
  }
  scope :eager_load_serialized_data, -> {}

  def search_id
    "podcast_episode_#{id}"
  end

  def comments_blob
    comments.pluck(:body_markdown).join(" ")
  end

  def path
    return unless podcast&.slug

    "/#{podcast.slug}/#{slug}"
  end

  def description
    ActionView::Base.full_sanitizer.sanitize(body)
  end

  def profile_image_url
    image_url || "http://41orchard.com/wp-content/uploads/2011/12/Robot-Chalkboard-Decal.gif"
  end

  def body_text
    ActionView::Base.full_sanitizer.sanitize(processed_html)
  end

  def score
    1 # When it is expected that a "commentable" has a score, this is the fallback.
  end

  def zero_method
    0
  end
  alias hotness_score zero_method
  alias search_score zero_method
  alias public_reactions_count zero_method

  def class_name
    self.class.name
  end

  def tag_keywords_for_search
    tags.pluck(:keywords_for_search).join
  end

  ## Useless stubs
  def nil_method
    nil
  end
  alias user_id nil_method
  alias co_author_ids nil_method

  private

  def bust_cache
    PodcastEpisodes::BustCacheWorker.perform_async(id, path, podcast_slug)
  end

  def process_html_and_prefix_all_images
    return if body.blank?

    self.processed_html = body
      .gsub("\r\n<p>&nbsp;</p>\r\n", "").gsub("\r\n<p>&nbsp;</p>\r\n", "")
      .gsub("\r\n<h3>&nbsp;</h3>\r\n", "").gsub("\r\n<h3>&nbsp;</h3>\r\n", "")

    self.processed_html = "<p>#{processed_html}</p>" unless processed_html.include?("<p>")

    doc = Nokogiri::HTML(processed_html)
    doc.css("img").each do |img|
      img_src = img.attr("src")

      next unless img_src

      cloudinary_img_src = Images::Optimizer.call(img_src, width: 725)
      self.processed_html = processed_html.gsub(img_src, cloudinary_img_src)
    end
  end
end
