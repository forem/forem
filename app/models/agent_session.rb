class AgentSession < ApplicationRecord
  TOOL_NAMES = %w[claude_code codex gemini_cli github_copilot pi opencode cursor].freeze
  MAX_RAW_DATA_SIZE = 10.megabytes

  belongs_to :user

  validates :title, presence: true, length: { maximum: 200 }
  validates :tool_name, presence: true, inclusion: { in: TOOL_NAMES }
  validates :raw_data, length: { maximum: MAX_RAW_DATA_SIZE }, allow_nil: true
  validates :slug, uniqueness: { scope: :user_id }, format: { with: /\A[0-9a-z\-_]+\z/ }, allow_nil: true

  validate :normalized_data_has_messages
  validate :normalized_data_not_too_large

  before_validation :generate_slug

  scope :published, -> { where(published: true) }

  def messages
    normalized_data.fetch("messages", [])
  end

  def curated_messages
    return messages if curated_selections.blank?

    selected = curated_selections.map(&:to_i).to_set
    messages.select { |m| selected.include?(m["index"]) }
  end

  def curated_messages_in_range(range)
    curated_messages.select { |m| range.cover?(m["index"].to_i) }
  end

  def find_slice(name)
    slices.find { |s| s["name"].to_s.downcase == name.to_s.downcase }
  end

  def messages_for_slice(name)
    slice = find_slice(name)
    return [] unless slice

    indices = (slice["indices"] || []).map(&:to_i).to_set
    messages.select { |m| indices.include?(m["index"].to_i) }
  end

  def metadata
    normalized_data.fetch("metadata", {})
  end

  def total_messages
    messages.size
  end

  def redactions
    session_metadata&.fetch("redactions", nil) || []
  end

  def total_redactions
    redactions.sum { |r| r["count"].to_i }
  end

  def curated_count
    curated_selections.present? ? curated_selections.size : total_messages
  end

  def to_param
    slug || id.to_s
  end

  def parse_and_normalize!(file_content, detected_tool: nil)
    self.tool_name = detected_tool if detected_tool
    parser = AgentSessionParsers::AutoDetect.parser_for(tool_name)
    parsed = parser.parse(file_content)

    # Scrub secrets from normalized data before persisting
    result = AgentSessionParsers::SensitiveDataScrubber.scrub(parsed)
    self.normalized_data = result.scrubbed_data
    self.session_metadata = normalized_data.fetch("metadata", {}).merge(
      "redactions" => result.redactions.map { |r| { "name" => r.pattern_name, "count" => r.count } },
    )

    # Also scrub raw data — keep it for context but with secrets replaced
    self.raw_data = AgentSessionParsers::SensitiveDataScrubber.scrub_text(file_content)
  end

  private

  def generate_slug
    return if slug.present?
    return unless title.present?

    truncated = title.length > 100 ? title[0..100].split[0...-1].join(" ") : title
    base = Sterile.sluggerize(truncated)
    self.slug = "#{base}-#{rand(100_000).to_s(26)}"
  end

  def normalized_data_has_messages
    return if normalized_data.blank?

    messages_data = normalized_data["messages"]
    return if messages_data.is_a?(Array)

    errors.add(:normalized_data, "must contain a messages array")
  end

  def normalized_data_not_too_large
    return if normalized_data.blank?

    if normalized_data.to_json.bytesize > MAX_RAW_DATA_SIZE
      errors.add(:normalized_data, "is too large (max #{MAX_RAW_DATA_SIZE / 1.megabyte}MB)")
    end
  end
end
