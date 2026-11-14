module Images
  MEDIUM_FONT_PATH = "app/assets/fonts/NotoSans-Medium.ttf".freeze
  BOLD_FONT_PATH = "app/assets/fonts/NotoSans-Bold.ttf".freeze
  TEMPLATE_PATH = "app/assets/images/social_template.png".freeze
  ROUNDED_MASK_PATH = "app/assets/images/rounded_mask.png".freeze

  # Generates the share image used when an article has no cover image: a quote
  # from the opening of the post in a browser-window card over a soft gradient,
  # with the author's avatar, name, date, and reading time.
  #
  # One image serves every platform. X overlays the post title in a dark label
  # inset at the bottom-left of link cards (about 29-73px up from the bottom of
  # this image), so the bottom X_KEEP_CLEAR pixels hold only background. The
  # card keeps the same margin at the top so it stays vertically centered where
  # nothing is overlaid (LinkedIn, Slack...).
  #
  # Rendered in-process via ForemNative (forem_core::social_image).
  class GenerateSocialImageMagickally
    WIDTH = 1200
    HEIGHT = 627
    X_KEEP_CLEAR = 80

    # Gradient: soft blobs drawn on a small canvas, blurred, then scaled up.
    MESH_WIDTH = 400
    MESH_HEIGHT = 209
    MESH_BLOBS = 7
    MESH_BLUR = "0x48".freeze

    WINDOW_WIDTH = 966
    WINDOW_STACK_OFFSET = 14 # two outlines peek out behind the window
    WINDOW_STACK_DEPTH = 2
    WINDOW_HEIGHT = HEIGHT - (2 * X_KEEP_CLEAR) - (WINDOW_STACK_OFFSET * WINDOW_STACK_DEPTH)
    WINDOW_RADIUS = 18
    WINDOW_STROKE = 4
    WINDOW_BAR_HEIGHT = 46
    WINDOW_X = (WIDTH - WINDOW_WIDTH - (WINDOW_STACK_OFFSET * WINDOW_STACK_DEPTH)) / 2
    WINDOW_Y = X_KEEP_CLEAR

    LOGO_HEIGHT = 30
    QUOTE_MARK_POINTSIZE = 150
    QUOTE_LEFT = 110 # relative to the window
    QUOTE_WIDTH = WINDOW_WIDTH - 160
    QUOTE_MAX_HEIGHT = WINDOW_HEIGHT - WINDOW_BAR_HEIGHT - 144
    QUOTE_MAX_POINTSIZE = 54
    QUOTE_MIN_POINTSIZE = 28
    BYLINE_HEIGHT = 92 # avatar row at the bottom of the window
    AVATAR_SIZE = 64
    NAME_POINTSIZE = 28
    META_POINTSIZE = 22
    MAX_NAME_LENGTH = 40

    PROFILE_STRIP_HEIGHT = 72
    PROFILE_AVATAR_SIZE = 112
    PROFILE_NAME_MAX_POINTSIZE = 38
    PROFILE_NAME_MIN_POINTSIZE = 24
    PROFILE_HANDLE_POINTSIZE = 22
    PROFILE_FOLLOW_WIDTH = 136
    PROFILE_FOLLOW_HEIGHT = 46
    PROFILE_FOLLOW_POINTSIZE = 21
    PROFILE_BIO_WIDTH = WINDOW_WIDTH - 88
    PROFILE_BIO_MAX_HEIGHT = 126
    PROFILE_BIO_MAX_POINTSIZE = 34
    PROFILE_BIO_MIN_POINTSIZE = 22
    PROFILE_FOOTER_HEIGHT = 70
    PROFILE_META_MAX_POINTSIZE = 22
    PROFILE_META_MIN_POINTSIZE = 16
    MAX_BIO_LENGTH = 160
    MAX_HANDLE_LENGTH = 32
    MAX_LOCATION_LENGTH = 34
    MAX_WEBSITE_LENGTH = 38

    TEXT_COLOR = "black".freeze
    SECONDARY_TEXT_COLOR = "#525252".freeze
    DIVIDER_COLOR = "#d8d8d8".freeze

    # Sampled from the Forem gradient set; used when there is no brand color.
    DEFAULT_PALETTES = [
      %w[#3333ff #12004a #ff4545 #6aa9ff #5b2bd6],
      %w[#ff4545 #ffb8ff #7a4af0 #8ec8f0 #ffffff],
      %w[#fff23a #ffffff #ffb8ff #e4f53a #ffd84a],
      %w[#4545ff #8ee0f5 #1a0450 #7a4af0 #c8c0f5],
    ].freeze
    UNSET_COLORS = %w[#000000 #111212].freeze
    PREWARM_MIN_TRUST_SCORE = 2
    PREWARM_TIMEOUT = 5

    def self.call(resource = nil)
      new(resource).call
    end

    def initialize(resource)
      @resource = resource
      @cached_subforem_id = nil
      @cached_logo_url = nil
      @cached_user_id = nil
      @cached_author_image_url = nil
    end

    def call
      case @resource
      when Article
        @user = @resource.user
        @resource.update_column(:social_image, generate_image(@resource, @user.setting.brand_color1))
        prewarm_social_image(@resource)
        ## We only need to bust article. All else can fade naturally
        EdgeCache::BustArticle.call(@resource)
      when ::Profile
        @user = @resource.user
        return unless @user

        update_user_social_image(generate_image(@user, @user.setting.brand_color1))
      when User
        @user = @resource
        update_user_social_image(generate_image(@user, @user.setting.brand_color1))
        @resource.articles.published.where(organization_id: nil, main_image: nil, video_thumbnail_url: [nil, ""])
          .find_each do |article|
          article.update_column(:social_image, generate_image(article, @user.setting.brand_color1))
        end
      else # Organization
        @user = @resource
        @resource.update_column(:social_image, generate_image(@resource, @user.bg_color_hex))
        EdgeCache::BustOrganization.call(@resource, @resource.slug)
        @resource.articles.published.where(main_image: nil, video_thumbnail_url: [nil, ""]).find_each do |article|
          article.update_column(:social_image, generate_image(article, @user.bg_color_hex))
        end
      end
    rescue OpenURI::HTTPError, Timeout::Error => e
      # Ignore external asset fetch failures (including HTTP and timeout errors), but log a warning.
      Rails.logger.warn("[GenerateSocialImageMagickally] Image fetch failed: #{e.message}")
    rescue StandardError => e
      Rails.logger.error(e)
      Rails.error.report(e)
    end

    private

    attr_reader :resource

    def prewarm_social_image(article)
      return if article.social_image.blank? || article.main_image.present?
      return unless @user&.author_trust_score.to_i >= PREWARM_MIN_TRUST_SCORE

      width, height = if article.published_at.present? && article.published_at <= Time.zone.local(2026, 3, 1)
                        [1000, 500]
                      else
                        [WIDTH, HEIGHT]
                      end
      optimized_url = Images::Optimizer.call(article.social_image, width: width, height: height, crop: "crop")
      return if optimized_url.blank? || optimized_url == article.social_image
      return unless safe_prewarm_url?(optimized_url)

      HTTParty.get(optimized_url, timeout: PREWARM_TIMEOUT, follow_redirects: false)
    rescue StandardError => e
      Rails.logger.warn("[GenerateSocialImageMagickally] Social image prewarm failed: #{e.message}")
    end

    def safe_prewarm_url?(url)
      uri = URI.parse(url.to_s)
      return false if uri.blank? || %w[http https].exclude?(uri.scheme) || uri.host.blank?

      !UnifiedEmbed::Tag.private_ip?(uri.host)
    rescue URI::Error
      false
    end

    def update_user_social_image(url)
      profile = @user.profile || @user.create_profile
      profile.update_column(:data, (profile.data || {}).merge("social_image" => url))
      EdgeCache::BustUser.call(@user)
    end

    def generate_image(subject, color)
      return generate_profile_image(subject, color) unless subject.is_a?(Article)

      read_files(subject)
      palette = palette_for(color, subject.id)
      card = {
        quote_image: render_quote(SocialImageQuote.call(subject)),
        name_image: render_text("label", display_name(@user.name), BOLD_FONT_PATH, NAME_POINTSIZE, TEXT_COLOR),
        meta_image: render_text("label", meta_line(subject), MEDIUM_FONT_PATH, META_POINTSIZE, SECONDARY_TEXT_COLOR),
        accent: accent_color(palette)
      }
      background = draw_background(palette, subject.id)
      generate_magickally(background, card)
    ensure
      [background, @logo_image, @author_image, @rounded_mask,
       *card&.values_at(:quote_image, :name_image, :meta_image)].each do |image|
        destroy_image(image)
      end
    end

    def generate_profile_image(subject, color)
      read_files(subject)
      palette = palette_for(color, subject.id)
      brand = profile_brand_color(color, palette)
      bio_text, bio_present = profile_bio(subject)
      bio_color = bio_present ? TEXT_COLOR : SECONDARY_TEXT_COLOR
      name_max_width = WINDOW_WIDTH - 44 - PROFILE_AVATAR_SIZE - 22 - PROFILE_FOLLOW_WIDTH - 64

      card = {
        profile: true,
        brand_color: brand,
        name_image: render_text_to_fit(
          display_name(subject.name), BOLD_FONT_PATH,
          PROFILE_NAME_MAX_POINTSIZE, PROFILE_NAME_MIN_POINTSIZE, TEXT_COLOR, name_max_width
        ),
        handle_image: render_text(
          "label", display_handle(subject.username), MEDIUM_FONT_PATH, PROFILE_HANDLE_POINTSIZE, SECONDARY_TEXT_COLOR
        ),
        follow_image: render_text("label", follow_label(subject), BOLD_FONT_PATH, PROFILE_FOLLOW_POINTSIZE, "white"),
        bio_image: render_bio(bio_text, bio_color),
        meta_image: render_text_to_fit(
          profile_meta_line(subject), MEDIUM_FONT_PATH,
          PROFILE_META_MAX_POINTSIZE, PROFILE_META_MIN_POINTSIZE, SECONDARY_TEXT_COLOR, PROFILE_BIO_WIDTH
        )
      }
      background = draw_background(palette, subject.id)
      generate_magickally(background, card)
    ensure
      [background, @logo_image, @author_image, @rounded_mask,
       *card&.values_at(:name_image, :handle_image, :follow_image, :bio_image, :meta_image)].each do |image|
        destroy_image(image)
      end
    end

    def generate_magickally(background, card)
      if card[:profile]
        draw_profile_window(background, card[:brand_color])
        result = add_logo(background)
        result = add_profile_header(result, card[:name_image], card[:handle_image], card[:follow_image])
        result = add_profile_bio(result, card[:bio_image])
        result = add_profile_card_avatar(result)
        result = add_profile_meta(result, card[:meta_image])
      else
        draw_window(background)
        result = add_logo(background)
        result = add_quote(result, card[:quote_image], card[:accent])
        result = add_profile_image(result)
        result = add_byline(result, card[:name_image], card[:meta_image])
      end
      upload_result(result)
    ensure
      destroy_image(result) unless result.equal?(background)
    end

    def draw_background(palette, seed)
      random = Random.new(seed.to_i)
      blobs = Array.new(MESH_BLOBS) do |i|
        x = random.rand(-30..(MESH_WIDTH + 30))
        y = random.rand(-30..(MESH_HEIGHT + 30))
        color = palette[(i % (palette.size - 1)) + 1]
        [x, y, random.rand(70..180), random.rand(50..130), color]
      end
      ForemNative.social_image_draw_background(palette.first, blobs)
    end

    def draw_window(result)
      ForemNative.social_image_draw_window(result)
    end

    def draw_profile_window(result, brand_color)
      ForemNative.social_image_draw_profile_window(result, brand_color)
    end

    def add_logo(result)
      return result unless @logo_image

      ForemNative.social_image_add_logo(result, @logo_image)
    end

    def add_quote(result, quote_image, accent)
      ForemNative.social_image_add_quote(result, quote_image, BOLD_FONT_PATH, accent)
    end

    # caption: wraps on real glyph widths; step the size down until the quote fits.
    # Longer quotes start smaller to save a few renders.
    def render_quote(quote)
      pointsize = QUOTE_MAX_POINTSIZE - (quote.length > 90 ? 4 : 0) - (quote.length > 140 ? 6 : 0)
      loop do
        image = render_text("caption", quote, BOLD_FONT_PATH, pointsize, TEXT_COLOR, width: QUOTE_WIDTH)
        fits = !image.respond_to?(:height) || image.height <= QUOTE_MAX_HEIGHT || pointsize <= QUOTE_MIN_POINTSIZE
        return image if fits

        image.destroy!
        pointsize -= 2
      end
    end

    def render_bio(bio, color)
      pointsize = PROFILE_BIO_MAX_POINTSIZE - (bio.length > 90 ? 4 : 0)
      loop do
        image = render_text("caption", bio, MEDIUM_FONT_PATH, pointsize, color, width: PROFILE_BIO_WIDTH)
        fits = !image.respond_to?(:height) ||
          image.height <= PROFILE_BIO_MAX_HEIGHT ||
          pointsize <= PROFILE_BIO_MIN_POINTSIZE
        return image if fits

        image.destroy!
        pointsize -= 2
      end
    end

    def render_text_to_fit(text, font, max_pointsize, min_pointsize, color, max_width)
      pointsize = max_pointsize
      loop do
        image = render_text("label", text, font, pointsize, color)
        return image if !image.respond_to?(:width) || image.width <= max_width || pointsize <= min_pointsize

        image.destroy!
        pointsize -= 2
      end
    end

    # Renders label: or caption: text in-process via ForemNative's TrueType rasterizer.
    def render_text(kind, text, font, pointsize, color, width: nil)
      content = text.to_s.strip.empty? ? "\u00A0" : text.to_s
      ForemNative.social_image_render_text(kind, content, font, pointsize, color, width: width)
    end

    def add_profile_image(result)
      return result unless @author_image

      ForemNative.social_image_add_profile_image(result, @author_image, @rounded_mask)
    rescue StandardError => e
      Rails.logger.warn("[GenerateSocialImageMagickally] Profile image processing failed: #{e.message}")
      # If processing the profile picture fails on a corrupt/truncated upload,
      # gracefully fall back to returning the social image without their avatar.
      result
    end

    def add_profile_card_avatar(result)
      return result unless @author_image

      ForemNative.social_image_add_profile_card_avatar(result, @author_image, @rounded_mask)
    rescue StandardError => e
      Rails.logger.warn("[GenerateSocialImageMagickally] Profile image processing failed: #{e.message}")
      result
    end

    def add_profile_header(result, name_image, handle_image, follow_image)
      ForemNative.social_image_add_profile_header(result, name_image, handle_image, follow_image)
    end

    def add_profile_bio(result, bio_image)
      ForemNative.social_image_add_profile_bio(result, bio_image)
    end

    def add_profile_meta(result, meta_image)
      ForemNative.social_image_add_profile_meta(result, meta_image)
    end

    def add_byline(result, name_image, meta_image)
      ForemNative.social_image_add_byline(result, name_image, meta_image)
    end

    def destroy_image(image)
      return unless image.respond_to?(:destroy!)
      return if image.respond_to?(:destroyed?) && image.destroyed?
      return if image.respond_to?(:tempfile) && image.tempfile && image.tempfile.path.nil?

      image.destroy!
    end

    def escape_text(text)
      text.to_s.gsub(/[\\"@%]/, "\\" => "\\\\", '"' => '\\"', "@" => "\\@", "%" => "\\%")
    end

    # NFKC turns "fancy" Unicode letters into plain ones the fonts can render.
    def clean_text(text)
      text.to_s.unicode_normalize(:nfkc)
        .gsub(/[\p{Extended_Pictographic}\uFE0F\u200D]/, "")
        .squish
    end

    def display_name(name)
      cleaned = clean_text(name)
      cleaned = @user&.username.to_s if cleaned.blank?
      cleaned.truncate(MAX_NAME_LENGTH)
    end

    def display_handle(username)
      cleaned = clean_text(username).delete_prefix("@")
      "@#{cleaned.truncate(MAX_HANDLE_LENGTH)}"
    end

    def follow_label(subject)
      scope = subject.is_a?(Organization) ? "views.organizations.follow" : "views.users.follow"
      I18n.t(scope, default: "Follow")
    end

    def profile_bio(subject)
      raw_bio = if subject.is_a?(Organization)
                  subject.summary.presence || subject.tag_line.presence
                else
                  subject.tag_line
                end
      cleaned = clean_text(raw_bio)
      if cleaned.blank?
        empty_key = subject.is_a?(Organization) ? "views.organizations.empty" : "views.users.empty"
        return [I18n.t(empty_key, default: "404 bio not found"), false]
      end

      truncated = if cleaned.length > MAX_BIO_LENGTH && cleaned.include?(" ")
                    cleaned.truncate(MAX_BIO_LENGTH, separator: /\s/, omission: "…")
                  else
                    cleaned.truncate(MAX_BIO_LENGTH, omission: "…")
                  end
      [truncated, true]
    end

    def profile_meta_line(subject)
      location = clean_text(subject.profile&.location).truncate(MAX_LOCATION_LENGTH).presence
      website = clean_website_url(subject.profile&.website_url)
      joined = if subject.respond_to?(:created_at) && subject.created_at.present?
                 "Joined #{subject.created_at.strftime('%b %Y')}"
               end
      [location, website, joined].compact_blank.join("  \u00B7  ")
    end

    def clean_website_url(url)
      cleaned = clean_text(url)
        .sub(%r{\Ahttps?://}i, "")
        .sub(/\Awww\./i, "")
        .chomp("/")
      cleaned.truncate(MAX_WEBSITE_LENGTH).presence
    end

    def meta_line(article)
      reading_time = I18n.t("views.articles.reading_time", count: [article.reading_time.to_i, 1].max)
      [article.readable_publish_date, reading_time].compact_blank.join("  \u00B7  ")
    end

    def upload_result(result)
      tempfile = Tempfile.new(["output", ".png"])
      result.write tempfile.path
      image_uploader = ArticleImageUploader.new.tap do |uploader|
        uploader.store!(tempfile)
      end
      # Don't forget to close and unlink (delete) the tempfile after you're done with it.
      tempfile.close
      tempfile.unlink

      # Return the uploaded url
      image_uploader.url
    end

    # A set brand color becomes an analogous palette: the color, its neighbors on
    # the color wheel, a light tint, and a deep shade. Without one, a Forem
    # gradient palette is chosen per article so cards vary.
    def palette_for(color, seed)
      hex = normalize_hex(color)
      return DEFAULT_PALETTES[seed.to_i % DEFAULT_PALETTES.size] if hex.nil? || UNSET_COLORS.include?(hex)

      hue, saturation, lightness = hex_to_hsl(hex)
      saturation = [saturation, 0.55].max
      [
        hex,
        hsl_to_hex(hue + 38, saturation, [lightness + 0.08, 0.62].min),
        hsl_to_hex(hue - 34, saturation, lightness),
        hsl_to_hex(hue, saturation * 0.6, 0.86),
        hsl_to_hex(hue + 12, saturation, 0.14),
      ]
    end

    def accent_color(palette)
      palette.detect { |color| luminance(color) < 0.45 } ||
        Settings::UserExperience.primary_brand_color_hex
    end

    def profile_brand_color(color, palette)
      hex = normalize_hex(color)
      return accent_color(palette) if hex.nil? || UNSET_COLORS.include?(hex)
      return hex if luminance(hex) <= 0.35

      hue, saturation, _lightness = hex_to_hsl(hex)
      hsl_to_hex(hue, [saturation, 0.55].max, 0.28)
    end

    def normalize_hex(color)
      value = color.to_s.strip.downcase
      value = "##{value[1] * 2}#{value[2] * 2}#{value[3] * 2}" if value.match?(/\A#\h{3}\z/)
      value.match?(/\A#\h{6}\z/) ? value : nil
    end

    def hex_channels(hex)
      hex.delete("#").scan(/../).map { |pair| pair.to_i(16) / 255.0 }
    end

    def hex_to_hsl(hex)
      r, g, b = hex_channels(hex)
      max = [r, g, b].max
      min = [r, g, b].min
      lightness = (max + min) / 2
      return [0.0, 0.0, lightness] if max == min

      delta = max - min
      saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min)
      hue = case max
            when r then ((g - b) / delta) + (g < b ? 6 : 0)
            when g then ((b - r) / delta) + 2
            else ((r - g) / delta) + 4
            end
      [hue * 60, saturation, lightness]
    end

    def hsl_to_hex(hue, saturation, lightness)
      hue %= 360.0
      saturation = saturation.clamp(0, 1)
      lightness = lightness.clamp(0, 1)
      chroma = (1 - ((2 * lightness) - 1).abs) * saturation
      x = chroma * (1 - (((hue / 60.0) % 2) - 1).abs)
      m = lightness - (chroma / 2)
      sectors = [[chroma, x, 0], [x, chroma, 0], [0, chroma, x], [0, x, chroma], [x, 0, chroma], [chroma, 0, x]]
      rgb = sectors[(hue / 60.0).floor % 6]
      "##{rgb.map { |channel| ((channel + m) * 255).round.to_s(16).rjust(2, '0') }.join}"
    end

    def luminance(hex)
      hex_channels(hex).map { |v| v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4 }
        .zip([0.2126, 0.7152, 0.0722]).sum { |channel, weight| channel * weight }
    end

    def read_files(subject = nil)
      # Get the subforem_id for this subject
      subforem_id = (subject.respond_to?(:subforem_id) && subject.subforem_id) || Subforem.cached_default_id
      user_id = @user&.id

      # Fetch logo URL only if subforem has changed. Prefer the horizontal header logo.
      if @cached_subforem_id != subforem_id
        resized_logo = Settings::General.resized_logo(subforem_id: subforem_id)
        @cached_logo_url = if resized_logo.present?
                             URL.local_image(resized_logo)
                           else
                             Settings::General.logo_png(subforem_id: subforem_id)
                           end
        @cached_subforem_id = subforem_id
      end

      # Fetch author image URL only if user has changed
      if @cached_user_id != user_id
        image = @user&.profile_image_90.to_s
        @cached_author_image_url = image.start_with?("http") ? image : Images::Profile::BACKUP_LINK
        @cached_user_id = user_id
      end

      @logo_image = @cached_logo_url.present? ? open_image(@cached_logo_url) : nil
      @author_image = open_author_image
      @rounded_mask = open_image(ROUNDED_MASK_PATH)
    end

    def open_author_image
      open_image(@cached_author_image_url)
    rescue ArgumentError => e
      Rails.logger.warn("[GenerateSocialImageMagickally] Profile image open failed: #{e.message}")
      nil
    end

    def open_image(path_or_url)
      ForemNative.social_image_open(path_or_url)
    end
  end
end
