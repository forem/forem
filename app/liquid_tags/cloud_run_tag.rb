class CloudRunTag < LiquidTagBase
  PARTIAL = "liquids/cloud_run".freeze
  REGISTRY_REGEXP = %r{\Ahttps?://[a-zA-Z0-9.-]+\.run\.app/?\z}

  HEIGHT_RANGE      = (200..2000).freeze
  WIDTH_RANGE       = (10..100).freeze
  DEFAULT_HEIGHT    = 600
  DEFAULT_WIDTH     = 100
  VALID_SCALE_MODES = %w[fit stretch].freeze
  NATIVE_REGEXP     = /\Anative:(\d+)x(\d+)\z/i

  # Legacy ratio presets — used only when no explicit height= is provided.
  RATIO_HEIGHTS = {
    "landscape" => 400,
    "portrait"  => 900,
    "default"   => DEFAULT_HEIGHT,
  }.freeze

  def initialize(_tag_name, input, _parse_context)
    super
    tokens = strip_tags(input).split

    @url        = parse_url(tokens.first.to_s)
    @height     = parse_height(tokens)
    @width      = parse_width(tokens)
    @scale_mode = parse_scale_mode(tokens)
    @native_w, @native_h = parse_native(tokens)

    # Nullify scale mode if native resolution is missing or scale isn't valid
    @scale_mode = nil unless @native_w && @native_h && @scale_mode
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        url:        @url,
        height:     @height,
        width:      @width,
        scale_mode: @scale_mode,
        native_w:   @native_w,
        native_h:   @native_h,
      },
    )
  end

  private

  def parse_url(url)
    stripped_url = url.strip
    raise StandardError, I18n.t("liquid_tags.cloud_run_tag.invalid_cloud_run_url") unless valid_url?(stripped_url)

    stripped_url
  end

  def valid_url?(url)
    url.match?(REGISTRY_REGEXP)
  end

  # Explicit `height=N` takes priority; falls back to legacy ratio preset.
  def parse_height(tokens)
    explicit = extract_int_param(tokens, "height")
    return explicit.clamp(HEIGHT_RANGE) if explicit

    # Legacy ratio keyword (landscape / portrait) — check if present in tokens
    ratio_token = tokens.find { |t| RATIO_HEIGHTS.key?(t&.downcase) }
    RATIO_HEIGHTS.fetch(ratio_token&.downcase, DEFAULT_HEIGHT)
  end

  def parse_width(tokens)
    val = extract_int_param(tokens, "width")
    val ? val.clamp(WIDTH_RANGE) : DEFAULT_WIDTH
  end

  def parse_scale_mode(tokens)
    token = tokens.find { |t| t.start_with?("scale:") }
    return nil unless token

    mode = token.split(":", 2).last.downcase
    VALID_SCALE_MODES.include?(mode) ? mode : nil
  end

  def parse_native(tokens)
    token = tokens.find { |t| t.match?(NATIVE_REGEXP) }
    return [nil, nil] unless token

    m = token.match(NATIVE_REGEXP)
    [m[1].to_i, m[2].to_i]
  end

  # Finds `key=N` in tokens and returns the integer, or nil if absent/invalid.
  def extract_int_param(tokens, key)
    token = tokens.find { |t| t.start_with?("#{key}=") }
    return nil unless token

    Integer(token.split("=", 2).last, 10)
  rescue ArgumentError
    nil
  end
end

Liquid::Template.register_tag("cloudrun", CloudRunTag)

UnifiedEmbed.register(CloudRunTag, regexp: CloudRunTag::REGISTRY_REGEXP)
