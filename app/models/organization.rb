include CloudinaryHelper

class Organization < ApplicationRecord
  acts_as_followable

  has_many :job_listings
  has_many :users
  has_many :articles
  has_many :collections
  has_many :display_ads

  validates :name, :summary, :url, :profile_image, presence: true
  validates :name,
            length: { maximum: 50 }
  validates :summary,
            length: { maximum: 250 }
  validates :tag_line,
            length: { maximum: 60 }
  validates :jobs_email, email: true, allow_blank: true
  validates :text_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  validates :bg_color_hex, format: /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  validates :slug,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[a-zA-Z0-9\-_]+\Z/ },
            length: { in: 2..18 },
            exclusion: { in: RESERVED_WORDS,
                         message: "%{value} is reserved." }
  validates :url, url: { allow_blank: true, no_local: true, schemes: ["https", "http"] }
  validates :secret, uniqueness: { allow_blank: true }
  validates :location, :email, :company_size, length: { maximum: 64 }
  validates :company_size, format: { with: /\A\d+\z/,
                                     message: "Integer only. No sign allowed.",
                                     allow_blank: true }
  validates :tech_stack, :story, length: { maximum: 640 }
  before_save :remove_at_from_usernames
  after_save  :bust_cache
  before_save :generate_secret
  before_validation :downcase_slug

  validate :unique_slug_including_users

  mount_uploader :profile_image, ProfileImageUploader
  mount_uploader :nav_image, ProfileImageUploader

  def username
    slug
  end

  def website_url
    url
  end

  def path
    "/#{slug}"
  end

  def generate_secret
    if secret.blank?
      self.secret = generated_random_secret
    end
  end

  def generated_random_secret
    SecureRandom.hex(50)
  end

  def resave_articles
    articles.each do |article|
      CacheBuster.new.bust(article.path)
      CacheBuster.new.bust(article.path + "?i=i")
      article.save
    end
  end


  private

  def remove_at_from_usernames
    self.twitter_username = twitter_username.gsub("@","") if twitter_username
    self.github_username = github_username.gsub("@","") if github_username
  end

  def downcase_slug
    self.slug = slug.downcase
  end

  def bust_cache
    CacheBuster.new.bust("/#{slug}")
    begin
      articles.each do |article|
        CacheBuster.new.bust(article.path)
      end
    rescue
      puts "Tag issue"
    end
  end
  handle_asynchronously :bust_cache

  def unique_slug_including_users
    errors.add(:slug, "is taken.") if User.find_by_username(slug)
  end
end
