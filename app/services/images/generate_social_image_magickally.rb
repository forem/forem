module Images
  MEDIUM_FONT_PATH = "app/assets/fonts/Roboto-Medium.ttf".freeze
  BOLD_FONT_PATH = "app/assets/fonts/Roboto-Bold.ttf".freeze
  TEMPLATE_PATH = "app/assets/images/social_template.png".freeze
  ROUNDED_MASK_PATH = "app/assets/images/rounded_mask.png".freeze

  class GenerateSocialImageMagickally
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
        read_files(@resource)
        url = generate_magickally(title: @resource.title,
                                  date: @resource.readable_publish_date,
                                  author_name: @user.name,
                                  color: @user.setting.brand_color1)
        @resource.update_column(:social_image, url)
        ## We only need to bust article. All else can fade naturally
        EdgeCache::BustArticle.call(@resource)
      elsif @resource.is_a?(User)
        @user = @resource
        @resource.articles.published.where(organization_id: nil, main_image: nil).find_each do |article|
          read_files(article)
          url = generate_magickally(title: article.title,
                                    date: article.readable_publish_date,
                                    author_name: @user.name,
                                    color: @user.setting.brand_color1)
          article.update_column(:social_image, url)
        end
      else # Organization
        @user = @resource
        @resource.articles.published.where(main_image: nil).find_each do |article|
          read_files(article)
          url = generate_magickally(title: article.title,
                                    date: article.readable_publish_date,
                                    author_name: @user.name,
                                    color: @user.bg_color_hex)
          article.update_column(:social_image, url)
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
        Honeybadger.notify(e)
      end
    rescue StandardError => e
      Rails.logger.error(e)
      Honeybadger.notify(e)
    end

    private

    def generate_magickally(title: nil, date: nil, author_name: nil, color: nil)
      @background_image.resize "1200x627!"
      result = draw_stripe(color)
      result = add_logo(result)
      result = add_text(result, title, date, author_name)
      result = add_profile_image(result)
      upload_result(result)
    end

    def draw_stripe(color)
      color = "#111212" if color == "#000000" # pure black has minimagick side effects
      @background_image.combine_options do |c|
        c.fill color
        c.draw "rectangle 0,0 1200,30" # adjust width according to your image width
      end
    end

    def add_logo(result)
      if @logo_image
        # Add white stroke to the overlay image
        @logo_image.combine_options do |c|
          c.stroke "white"
          c.strokewidth "4"
          c.fill "none"
          c.draw "rectangle 0,0 1200,1200" # adjust as needed based on image size
        end

        # Resize the overlay image
        @logo_image.resize "77x77"

        result = @background_image.composite(@logo_image) do |c|
          c.compose "Over" # OverCompositeOp
          c.geometry "+1020+466" # move the overlay to the top left
        end
      end
      result
    end

    def add_text(result, title, date, author_name)
      title = title.truncate(128)
      title = wrap_text(title)
      font_size = calculate_font_size(title)

      result.combine_options do |c|
        escaped_title = title.gsub('"', '\\"')
        c.gravity "West" # Set the origin for the text at the top left corner
        c.pointsize font_size.to_s
        c.draw "text 96,-49 \"#{escaped_title}\"" # Start drawing text 90 from the left and slightly north, with double quotes around the title
        c.fill "black"
        c.font BOLD_FONT_PATH.to_s
      end

      result.combine_options do |c|
        escaped_name = author_name.gsub('"', '\\"')
        c.gravity "Southwest"
        c.pointsize "40"
        c.draw "text 187,110 \"#{escaped_name}\"" # adjust coordinates as needed
        c.fill "black"
        c.font MEDIUM_FONT_PATH.to_s
      end

      result.combine_options do |c|
        c.gravity "Southwest"
        c.pointsize "32"
        c.draw "text 187,75 \"#{date}\"" # adjust coordinates as needed
        c.fill "#525252"
      end
    end

    def add_profile_image(result)
      profile_image_size = "77x77"
      profile_image_location = "+96+79"

      # Flatten animated GIFs to a single frame and convert to PNG immediately to prevent 
      # mogrify from attempting to resize hundreds of frames, sparking Timeout::Errors.
      @author_image.collapse!
      @author_image.format("png")
      @author_image.resize profile_image_size

      # Add subtext and author image
      result = result.composite(@author_image) do |c|
        c.compose "Over"
        c.gravity "Southwest"
        c.geometry profile_image_location
      end

      @rounded_mask.resize profile_image_size

      result.composite(@rounded_mask) do |c|
        c.compose "Over"
        c.gravity "Southwest"
        c.geometry profile_image_location
      end
    rescue Timeout::Error, StandardError => e
      Honeybadger.notify(e)
      # If processing the profile picture triggers a mogrify lockup, 
      # gracefully fall back to returning the social image without their avatar.
      result
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

    attr_reader :resource

    def calculate_font_size(text)
      text_length = text.length

      if text_length < 18
        110
      elsif text_length < 40
        96
      elsif text_length < 55
        81
      elsif text_length < 70
        75
      else
        62
      end
    end

    def wrap_text(text)
      line_width = if text.length < 40
                     20
                   elsif text.length < 70
                     27
                   else
                     35
                   end
      text.split("\n").map do |line|
        line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
      end * "\n"
    end

    def read_files(article)
      # Get the subforem_id for this article
      subforem_id = article.subforem_id || Subforem.cached_default_id
      user_id = @user&.id

      # Fetch logo URL only if subforem has changed
      if @cached_subforem_id != subforem_id
        @cached_logo_url = Settings::General.logo_png(subforem_id: subforem_id)
        @cached_subforem_id = subforem_id
      end

      # Fetch author image URL only if user has changed
      if @cached_user_id != user_id
        image = @user&.profile_image_90.to_s
        @cached_author_image_url = image.start_with?("http") ? image : Images::Profile::BACKUP_LINK
        @cached_user_id = user_id
      end

      # Always create fresh image objects since MiniMagick modifies them in place
      @background_image = MiniMagick::Image.open(TEMPLATE_PATH)
      @logo_image = @cached_logo_url.present? ? MiniMagick::Image.open(@cached_logo_url) : nil
      @author_image = MiniMagick::Image.open(@cached_author_image_url)
      @rounded_mask = MiniMagick::Image.open(ROUNDED_MASK_PATH)
    end
  end
end
