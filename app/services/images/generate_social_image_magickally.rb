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
  # Production runs ImageMagick 6, so stick to IM6-compatible operations.
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
      if @resource.is_a?(Article)
        @user = @resource.user
        @resource.update_column(:social_image, generate_image(@resource, @user.setting.brand_color1))
        ## We only need to bust article. All else can fade naturally
        EdgeCache::BustArticle.call(@resource)
      elsif @resource.is_a?(User)
        @user = @resource
        @resource.articles.published.where(organization_id: nil, main_image: nil).find_each do |article|
          article.update_column(:social_image, generate_image(article, @user.setting.brand_color1))
        end
      else # Organization
        @user = @resource
        @resource.articles.published.where(main_image: nil).find_each do |article|
          article.update_column(:social_image, generate_image(article, @user.bg_color_hex))
        end
      end
    rescue OpenURI::HTTPError, Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
      # Ignore external asset fetch failures (including HTTP and timeout errors), but log a warning.
      Rails.logger.warn("[GenerateSocialImageMagickally] Image fetch failed: #{e.message}")
    rescue MiniMagick::Error => e
      # Status 15 is SIGTERM (often from Sidekiq memory killers). No need to alert Honeybadger.
      if e.message.include?("status: 15")
        Rails.logger.warn("[GenerateSocialImageMagickally] MiniMagick terminated by SIGTERM")
      else
        Rails.error.report(e)
      end
    rescue StandardError => e
      Rails.logger.error(e)
      Rails.error.report(e)
    end

    private

    attr_reader :resource

    def generate_image(article, color)
      read_files(article)
      palette = palette_for(color, article.id)
      card = {
        quote_image: render_quote(SocialImageQuote.call(article)),
        name_image: render_text("label", display_name(@user.name), BOLD_FONT_PATH, NAME_POINTSIZE, TEXT_COLOR),
        meta_image: render_text("label", meta_line(article), MEDIUM_FONT_PATH, META_POINTSIZE, SECONDARY_TEXT_COLOR),
        accent: accent_color(palette)
      }
      background = draw_background(palette, article.id)
      generate_magickally(background, card)
    ensure
      background&.destroy!
      card&.values_at(:quote_image, :name_image, :meta_image)&.compact&.each(&:destroy!)
    end

    def generate_magickally(background, card)
      draw_window(background)
      result = add_logo(background)
      result = add_quote(result, card[:quote_image], card[:accent])
      result = add_profile_image(result)
      result = add_byline(result, card[:name_image], card[:meta_image])
      upload_result(result)
    end

    def draw_background(palette, seed)
      random = Random.new(seed.to_i)
      # MIFF is uncompressed, so the intermediate steps skip PNG encoding (the slow part).
      tempfile = Tempfile.new(["social_background", ".miff"])
      MiniMagick::Tool::Convert.new do |convert|
        convert.size "#{MESH_WIDTH}x#{MESH_HEIGHT}"
        convert << "xc:#{palette.first}"
        MESH_BLOBS.times do |i|
          x = random.rand(-30..(MESH_WIDTH + 30))
          y = random.rand(-30..(MESH_HEIGHT + 30))
          convert.fill palette[(i % (palette.size - 1)) + 1]
          convert.draw "ellipse #{x},#{y} #{random.rand(70..180)},#{random.rand(50..130)} 0,360"
        end
        convert.blur MESH_BLUR
        convert.filter "Gaussian"
        convert.resize "#{WIDTH}x#{HEIGHT}!"
        convert << tempfile.path
      end
      MiniMagick::Image.new(tempfile.path, tempfile)
    end

    def draw_window(result)
      x0 = WINDOW_X
      x1 = WINDOW_X + WINDOW_WIDTH
      y1 = WINDOW_Y + WINDOW_HEIGHT
      bar_y = WINDOW_Y + WINDOW_BAR_HEIGHT
      dot_y = WINDOW_Y + (WINDOW_BAR_HEIGHT / 2)

      result.combine_options do |c|
        c.fill "white"
        c.stroke TEXT_COLOR
        c.strokewidth WINDOW_STROKE.to_s
        WINDOW_STACK_DEPTH.downto(1) do |depth|
          offset = depth * WINDOW_STACK_OFFSET
          c.draw "roundrectangle #{x0 + offset},#{WINDOW_Y + offset} #{x1 + offset},#{y1 + offset} " \
                 "#{WINDOW_RADIUS},#{WINDOW_RADIUS}"
        end
        c.draw "roundrectangle #{x0},#{WINDOW_Y} #{x1},#{y1} #{WINDOW_RADIUS},#{WINDOW_RADIUS}"
        c.draw "line #{x0},#{bar_y} #{x1},#{bar_y}"
        c.stroke "none"
        c.fill TEXT_COLOR
        3.times do |i|
          dot_x = x1 - 34 - (i * 22)
          c.draw "circle #{dot_x},#{dot_y} #{dot_x + 6},#{dot_y}"
        end
        divider_y = y1 - BYLINE_HEIGHT - 14
        c.stroke DIVIDER_COLOR
        c.strokewidth "2"
        c.draw "line #{x0 + 40},#{divider_y} #{x1 - 40},#{divider_y}"
      end
    end

    def add_logo(result)
      return result unless @logo_image

      @logo_image.resize "x#{LOGO_HEIGHT}"
      result.composite(@logo_image) do |c|
        c.compose "Over"
        c.geometry "+#{WINDOW_X + 18}+#{WINDOW_Y + ((WINDOW_BAR_HEIGHT - LOGO_HEIGHT) / 2)}"
      end
    end

    # ImageMagick applies settings in order, so font/fill/pointsize must come
    # before each draw or the text renders in the default font.
    def add_quote(result, quote_image, accent)
      body_top = WINDOW_Y + WINDOW_BAR_HEIGHT
      result.combine_options do |c|
        c.gravity "NorthWest"
        c.font BOLD_FONT_PATH.to_s
        c.fill accent
        c.pointsize QUOTE_MARK_POINTSIZE.to_s
        c.draw "text #{WINDOW_X + 26},#{body_top - 30} \"\u201C\""
      end

      quote_y = body_top + 24 + [(QUOTE_MAX_HEIGHT + 16 - quote_image.height) / 2, 0].max
      result.composite(quote_image) do |c|
        c.compose "Over"
        c.geometry "+#{WINDOW_X + QUOTE_LEFT}+#{quote_y}"
      end
    end

    # caption: wraps on real glyph widths; step the size down until the quote fits.
    # Longer quotes start smaller to save a few renders.
    def render_quote(quote)
      pointsize = QUOTE_MAX_POINTSIZE - (quote.length > 90 ? 4 : 0) - (quote.length > 140 ? 6 : 0)
      loop do
        image = render_text("caption", quote, BOLD_FONT_PATH, pointsize, TEXT_COLOR, width: QUOTE_WIDTH)
        return image if image.height <= QUOTE_MAX_HEIGHT || pointsize <= QUOTE_MIN_POINTSIZE

        image.destroy!
        pointsize -= 2
      end
    end

    # All user-provided text goes through label:/caption: (never -draw) so it is
    # escaped the same way on ImageMagick 6 and 7. Unescaped, a leading "@" makes
    # ImageMagick read a file and "%" sequences expand to image properties.
    def render_text(kind, text, font, pointsize, color, width: nil)
      tempfile = Tempfile.new(["social_text", ".png"])
      MiniMagick::Tool::Convert.new do |convert|
        convert.background "none"
        convert.fill color
        convert.font font.to_s
        convert.pointsize pointsize.to_s
        if width
          convert.interline_spacing "-4"
          convert.size "#{width}x"
          convert.gravity "West"
        end
        convert << "#{kind}:#{escape_text(text)}"
        convert << tempfile.path
      end
      MiniMagick::Image.new(tempfile.path, tempfile)
    end

    def add_profile_image(result)
      x = WINDOW_X + 40
      y = WINDOW_Y + WINDOW_HEIGHT - BYLINE_HEIGHT

      # Flatten animated GIFs to a single frame and convert to PNG immediately to prevent
      # mogrify from attempting to resize hundreds of frames, sparking Timeout::Errors.
      @author_image.collapse!
      @author_image.format("png")
      @author_image.resize "#{AVATAR_SIZE}x#{AVATAR_SIZE}!"
      @rounded_mask.resize "#{AVATAR_SIZE}x#{AVATAR_SIZE}"

      # The mask paints white corners, which blend into the white window.
      result = result.composite(@author_image) do |c|
        c.compose "Over"
        c.geometry "+#{x}+#{y}"
      end
      result = result.composite(@rounded_mask) do |c|
        c.compose "Over"
        c.geometry "+#{x}+#{y}"
      end
      radius = AVATAR_SIZE / 2
      result.combine_options do |c|
        c.fill "none"
        c.stroke TEXT_COLOR
        c.strokewidth "3"
        c.draw "circle #{x + radius},#{y + radius} #{x + radius},#{y - 1}"
      end
    rescue Timeout::Error, StandardError => e
      Rails.error.report(e)
      # If processing the profile picture triggers a mogrify lockup,
      # gracefully fall back to returning the social image without their avatar.
      result
    end

    def add_byline(result, name_image, meta_image)
      text_x = WINDOW_X + 40 + AVATAR_SIZE + 20
      top = WINDOW_Y + WINDOW_HEIGHT - BYLINE_HEIGHT

      result = result.composite(name_image) do |c|
        c.compose "Over"
        c.geometry "+#{text_x}+#{top - 2}"
      end
      result.composite(meta_image) do |c|
        c.compose "Over"
        c.geometry "+#{text_x}+#{top + 36}"
      end
    end

    def escape_text(text)
      text.to_s.gsub(/[\\"@%]/, "\\" => "\\\\", '"' => '\\"', "@" => "\\@", "%" => "\\%")
    end

    # NFKC turns "fancy" Unicode letters into plain ones the fonts can render.
    def display_name(name)
      name.to_s.unicode_normalize(:nfkc)
        .gsub(/[\p{Extended_Pictographic}\uFE0F\u200D]/, "")
        .squish.truncate(MAX_NAME_LENGTH)
    end

    def meta_line(article)
      reading_time = I18n.t("views.articles.reading_time", count: [article.reading_time.to_i, 1].max)
      [article.readable_publish_date, reading_time].compact_blank.join("  \u00B7  ")
    end

    def upload_result(result)
      result.combine_options do |c|
        c.alpha "off"
        c.depth "8"
      end
      result.format("png")
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
      return [0, 0, lightness] if max == min

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
      hue %= 360
      saturation = saturation.clamp(0, 1)
      lightness = lightness.clamp(0, 1)
      chroma = (1 - ((2 * lightness) - 1).abs) * saturation
      x = chroma * (1 - (((hue / 60) % 2) - 1).abs)
      m = lightness - (chroma / 2)
      sectors = [[chroma, x, 0], [x, chroma, 0], [0, chroma, x], [0, x, chroma], [x, 0, chroma], [chroma, 0, x]]
      rgb = sectors[(hue / 60).floor % 6]
      "##{rgb.map { |channel| ((channel + m) * 255).round.to_s(16).rjust(2, '0') }.join}"
    end

    def luminance(hex)
      hex_channels(hex).map { |v| v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4 }
        .zip([0.2126, 0.7152, 0.0722]).sum { |channel, weight| channel * weight }
    end

    def read_files(article)
      # Get the subforem_id for this article
      subforem_id = article.subforem_id || Subforem.cached_default_id
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

      # Always create fresh image objects since MiniMagick modifies them in place
      @logo_image = @cached_logo_url.present? ? MiniMagick::Image.open(@cached_logo_url) : nil
      @author_image = MiniMagick::Image.open(@cached_author_image_url)
      @rounded_mask = MiniMagick::Image.open(ROUNDED_MASK_PATH)
    end
  end
end
