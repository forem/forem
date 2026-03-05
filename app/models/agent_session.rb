class AgentSession < ApplicationRecord
  TOOL_NAMES = %w[claude_code codex gemini_cli github_copilot pi].freeze
  MAX_CURATED_DATA_SIZE = 10.megabytes

  belongs_to :user

  validates :title, presence: true, length: { maximum: 200 }
  validates :tool_name, presence: true, inclusion: { in: TOOL_NAMES }
  validates :slug, uniqueness: true, format: { with: /\A[0-9a-z\-_]+\z/ }, allow_nil: true

  validate :data_has_messages
  validate :data_not_too_large

  before_validation :generate_slug
  after_destroy :delete_s3_object

  scope :published, -> { where(published: true) }

  def messages
    curated_data.fetch("messages", [])
  end

  def curated_messages
    messages
  end

  def curated_messages_in_range(range)
    messages.select { |m| range.cover?(m["index"].to_i) }
  end

  def find_slice(name)
    slices.detect { |s| s["name"].to_s.downcase == name.to_s.downcase }
  end

  def messages_for_slice(name)
    slice = find_slice(name)
    return [] unless slice

    indices = (slice["indices"] || []).to_set(&:to_i)
    messages.select { |m| indices.include?(m["index"].to_i) }
  end

  def metadata
    curated_data.fetch("metadata", {})
  end

  def total_messages
    messages.size
  end

  def redactions
    session_metadata&.dig("redactions") || []
  end

  def total_redactions
    redactions.sum { |r| r["count"].to_i }
  end

  def curated_count
    messages.size
  end

  def to_param
    slug || id.to_s
  end

  def s3_session?
    s3_key.present?
  end

  private

  def generate_slug
    return if slug.present?
    return if title.blank?

    truncated = title.length > 100 ? title[0..100].split[0...-1].join(" ") : title
    base = Sterile.sluggerize(truncated)
    self.slug = "#{base}-#{SecureRandom.alphanumeric(6).downcase}"
  end

  def data_has_messages
    return if curated_data.blank? || curated_data == {}

    messages_data = curated_data["messages"]
    unless messages_data.is_a?(Array)
      errors.add(:curated_data, "must contain a messages array")
    end
    # Sessions with just s3_key and no curated_data yet (draft state) are valid
  end

  def data_not_too_large
    return if curated_data.blank? || curated_data == {}

    if curated_data.to_json.bytesize > MAX_CURATED_DATA_SIZE
      errors.add(:curated_data, "is too large (max #{MAX_CURATED_DATA_SIZE / 1.megabyte}MB)")
    end
  end

  def delete_s3_object
    return unless s3_key.present? && AgentSessions::S3Storage.enabled?

    AgentSessions::S3Storage.delete(s3_key)
  end
end
