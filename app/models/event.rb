class Event < ApplicationRecord
  mount_uploader :cover_image, CoverImageUploader
  mount_uploader :profile_image, ProfileImageUploader

  validates :title, length: { maximum: 90 }
  validates :location_url, url: { allow_blank: true, schemes: %w[https http] }
  validate :end_time_after_start
  validates :slug, presence: { if: :published? }, format: /\A[0-9a-z-]*\z/
  before_validation :evaluate_markdown
  before_validation :create_slug
  after_save :bust_cache

  scope :in_the_future_and_published, lambda {
    where("starts_at > ?", Time.current)
      .where(published: true)
  }

  scope :in_the_past_and_published, lambda {
    where("starts_at < ?", Time.current)
      .where(published: true)
  }

  private

  def evaluate_markdown
    self.description_html = MarkdownProcessor::Parser.new(description_markdown).evaluate_markdown
  end

  def end_time_after_start
    if ends_at.nil? || starts_at.nil?
      errors.add(:starts_at, "and ends_at must not be nil")
    elsif ends_at < starts_at
      errors.add(:ends_at, "must be after start date")
    end
  end

  def create_slug
    self.slug = title_to_slug if slug.blank? && title.present? && published
  end

  def title_to_slug
    downcase = "#{id}-#{category}-#{title}"
    "#{downcase.parameterize}-#{starts_at.strftime('%m-%d-%Y')}"
  end

  def bust_cache
    Events::BustCacheWorker.perform_async
  end
end
