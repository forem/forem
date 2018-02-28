class Event < ApplicationRecord
  mount_uploader :cover_image, CoverImageUploader
  before_validation :evaluate_markdown

  validates :title, length: { maximum: 45 }
  validates :location_url, url: { allow_blank: true, schemes: ["https", "http"] }
  validate :end_time_after_start
  after_save :bust_cache

  scope :in_the_future_and_published, -> {
    where("starts_at > ?", Time.now).
      where(published: true)
  }

  scope :in_the_past_and_published, -> {
    where("starts_at < ?", Time.now).
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

  def bust_cache
    CacheBuster.new.bust("/events")
    CacheBuster.new.bust("/events?i=i")
  end
end
