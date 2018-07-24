include CloudinaryHelper
include ActionView::Helpers::SanitizeHelper

class PodcastEpisode < ApplicationRecord
  include AlgoliaSearch

  acts_as_taggable

  belongs_to :podcast
  has_many :comments, as: :commentable

  mount_uploader :image, ProfileImageUploader
  mount_uploader :social_image, ProfileImageUploader

  validates :title, presence: true
  validates :slug, presence: true
  validates :media_url, presence: true, uniqueness: true
  validates :guid, presence: true, uniqueness: true


  after_update :purge
  after_create :purge_all
  after_destroy :purge, :purge_all
  after_save    :bust_cache

  before_validation :prefix_all_images

  algoliasearch per_environment: true do
    attribute :id
    add_index "searchables",
                  id: :index_id,
                  per_environment: true do
      attribute :title, :body, :quote, :summary, :subtitle, :website_url,
      :published_at, :comments_count, :path, :class_name,
      :user_name, :user_username, :published, :comments_blob,
      :body_text, :tag_list, :tag_keywords_for_search,
      :positive_reactions_count, :search_score
      attribute :user do
        { name: podcast.name,
          username: user_username,
          profile_image_90: ProfileImage.new(user).get(90) }
      end
      searchableAttributes ["unordered(title)",
                            "body_text",
                            "tag_list",
                            "tag_keywords_for_search",
                            "user_name",
                            "user_username",
                            "comments_blob"]
      attributesForFaceting [:class_name]
      customRanking ["desc(search_score)", "desc(hotness_score)"]
    end
  end

  def user_username
    podcast_slug
  end

  def user_name
    podcast_title
  end

  def comments_blob
    comments.pluck(:body_markdown).join(" ")
  end

  def index_id
    "podcast_episodes-#{id}"
  end

  def path
    "/#{podcast.slug}/#{slug}"
  end
  
  def podcast_slug
    podcast.slug
  end

  def podcast_image_url
    podcast.image_url
  end

  def podcast_title
    podcast.title
  end

  def published_at_int
    published_at.to_i
  end

  def published
    true
  end

  def description
    strip_tags(body)
  end

  def main_image
    nil
  end

  def profile_image_url
    image_url || "http://41orchard.com/wp-content/uploads/2011/12/Robot-Chalkboard-Decal.gif"
  end

  def body_text
    ActionView::Base.full_sanitizer.sanitize(processed_html)
  end

  def published_at_date_slashes
    published_at.to_date.strftime("%m/%d/%Y") if published_at
  end

  def user
    podcast
  end

  def zero_method
    0
  end  
  alias_method :hotness_score, :zero_method
  alias_method :search_score, :zero_method
  alias_method :positive_reactions_count, :zero_method

  def bust_cache
    purge
    purge_all
    begin
      cache_buster = CacheBuster.new
      cache_buster.bust(path)
      cache_buster.bust("/"+podcast_slug)
      cache_buster.bust("/pod")
      cache_buster.bust(path)
    rescue

    end
    purge
    purge_all
  end

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
  alias_method :user_id, :nil_method
  alias_method :second_user_id, :nil_method
  alias_method :third_user_id, :nil_method

  def liquid_tags_used
    []
  end

  private

  def prefix_all_images
    return unless body.present?
    self.processed_html = body.gsub("\r\n<p>&nbsp;</p>\r\n","").gsub("\r\n<p>&nbsp;</p>\r\n","").gsub("\r\n<h3>&nbsp;</h3>\r\n","").gsub("\r\n<h3>&nbsp;</h3>\r\n","")
    self.processed_html = "<p>#{self.processed_html}</p>" unless processed_html.include?("<p>")
    doc = Nokogiri::HTML(processed_html)
    doc.css("img").each do |img|
      if img.attr('src') && (img.attr('src').include? ".gif")
        quality = 66
      else
        quality = "auto"
      end
      if img.attr('src')
        self.processed_html = processed_html.gsub(img.attr('src'),
          cl_image_path(img.attr('src'),
           :type=>"fetch",
           :width => 725,
           :crop => "limit",
           :quality => quality,
           :flags => "progressive",
           :fetch_format => "auto",
           :sign_url => true))
      end
    end
  end


end
