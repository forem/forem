class AgentSession < ApplicationRecord
  TOOL_NAMES = %w[claude_code codex gemini_cli github_copilot pi].freeze
  MAX_RAW_DATA_SIZE = 10.megabytes
  MAX_CURATED_DATA_SIZE = 50.megabytes

  belongs_to :user

  validates :title, presence: true, length: { maximum: 200 }
  validates :tool_name, presence: true, inclusion: { in: TOOL_NAMES }
  validates :raw_data, length: { maximum: MAX_RAW_DATA_SIZE }, allow_nil: true
  validates :slug, uniqueness: true, format: { with: /\A[0-9a-z\-_]+\z/ }, allow_nil: true

  validate :data_has_messages
  validate :data_not_too_large

  before_validation :generate_slug
  after_destroy :delete_s3_object

  scope :published, -> { where(published: true) }

  def messages
    if curated_data.present? && curated_data["messages"].present?
      curated_data["messages"]
    else
      normalized_data.fetch("messages", [])
    end
  end

  def curated_messages
    if curated_data.present? && curated_data["messages"].present?
      curated_data["messages"]
    elsif curated_selections.present?
      selected = curated_selections.to_set(&:to_i)
      normalized_data.fetch("messages", []).select { |m| selected.include?(m["index"]) }
    else
      normalized_data.fetch("messages", [])
    end
  end

  def curated_messages_in_range(range)
    curated_messages.select { |m| range.cover?(m["index"].to_i) }
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
    if curated_data.present? && curated_data["metadata"].present?
      curated_data["metadata"]
    else
      normalized_data.fetch("metadata", {})
    end
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
    if curated_data.present? && curated_data["messages"].present?
      curated_data["messages"].size
    elsif curated_selections.present?
      curated_selections.size
    else
      total_messages
    end
  end

  def to_param
    slug || id.to_s
  end

  def s3_session?
    s3_key.present?
  end

  def parse_and_normalize!(file_content, detected_tool: nil)
    self.tool_name = detected_tool if detected_tool
    begin
      parser = AgentSessionParsers::AutoDetect.parser_for(tool_name)
      parsed = parser.parse(file_content)
    rescue ArgumentError, JSON::ParserError, EncodingError => e
      raise AgentSessionParsers::ParseError, e.message
    end

    # Scrub secrets from normalized data before persisting
    result = AgentSessionParsers::SensitiveDataScrubber.scrub(parsed)
    self.normalized_data = result.scrubbed_data
    self.session_metadata = normalized_data.fetch("metadata", {}).merge(
      "redactions" => result.redactions.map { |r| { "name" => r.pattern_name, "count" => r.match_count } },
    )

    # Also scrub raw data — keep it for context but with secrets replaced
    self.raw_data = AgentSessionParsers::SensitiveDataScrubber.scrub_text(file_content)
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
    if curated_data.present? && curated_data != {}
      messages_data = curated_data["messages"]
      unless messages_data.is_a?(Array)
        errors.add(:curated_data, "must contain a messages array")
      end
    elsif normalized_data.present? && normalized_data != {}
      messages_data = normalized_data["messages"]
      unless messages_data.is_a?(Array)
        errors.add(:normalized_data, "must contain a messages array")
      end
    end
    # Allow saving with just s3_key and no curated_data yet (draft state)
  end

  def data_not_too_large
    if curated_data.present? && curated_data != {}
      if curated_data.to_json.bytesize > MAX_CURATED_DATA_SIZE
        errors.add(:curated_data, "is too large (max #{MAX_CURATED_DATA_SIZE / 1.megabyte}MB)")
      end
    elsif normalized_data.present? && normalized_data != {}
      if normalized_data.to_json.bytesize > MAX_RAW_DATA_SIZE
        errors.add(:normalized_data, "is too large (max #{MAX_RAW_DATA_SIZE / 1.megabyte}MB)")
      end
    end
  end

  def delete_s3_object
    return unless s3_key.present? && AgentSessions::S3Storage.enabled?

    AgentSessions::S3Storage.delete(s3_key)
  end
end
