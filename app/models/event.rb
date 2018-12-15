class Event < ApplicationRecord
  mount_uploader :cover_image, CoverImageUploader
  mount_uploader :profile_image, ProfileImageUploader

  validates :title, length: { maximum: 90 }
  validates :location_url, url: { allow_blank: true, schemes: ["https", "http"] }
  validate :end_time_after_start
  validates :slug, presence: { if: :published? }, format: /\A[0-9a-z-]*\z/
  after_save :bust_cache

  before_validation :create_slug
  before_validation :evaluate_markdown

  scope :in_the_future_and_published, -> {
    where("starts_at > ?", Time.current).
      where(published: true)
  }

  scope :in_the_past_and_published, -> {
    where("starts_at < ?", Time.current).
      where(published: true)
  }

  private

  def evaluate_markdown
    self.description_html = MarkdownParser.new(description_markdown).evaluate_markdown
  end

  def end_time_after_start
    if ends_at.nil? || starts_at.nil?
      errors.add(:starts_at, "and ends_at must not be nil")
    elsif ends_at < starts_at
      errors.add(:ends_at, "must be after start date")
    end
  end

  def create_slug
    if slug.blank? && title.present? && published
      self.slug = title_to_slug
    end
  end

  def title_to_slug
    downcase = (id.to_s + "-" + category + "-" + title).to_s.downcase
    downcase.tr(" ", "-").gsub(/[^\w-]/, "").tr("_", "") + "-" + starts_at.strftime("%m-%d-%Y")
  end

  def bust_cache
    cache_buster = CacheBuster.new
    cache_buster.bust("/events")
    cache_buster.bust("/events?i=i")
  end
end
