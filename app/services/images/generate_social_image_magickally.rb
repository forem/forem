module Images
  MEDIUM_FONT_PATH = Rails.root.join("app/assets/fonts/Roboto-Medium.ttf").freeze
  BOLD_FONT_PATH = Rails.root.join("app/assets/fonts/Roboto-Bold.ttf").freeze
  TEMPLATE_PATH = Rails.root.join("app/assets/images/social_template.png").freeze
  ROUNDED_MASK_PATH = Rails.root.join("app/assets/images/rounded_mask.png").freeze

  class GenerateSocialImageMagickally
    def self.call(resource = nil)
      new(resource).call
    end

    def initialize(resource)
      @resource = resource
      @logo_url = Settings::General.logo_png
    end

    def call
      if @resource.is_a?(Article)
        @user = @resource.user
        read_files
        url = generate_magickally(title: @resource.title,
                                  date: @resource.readable_publish_date,
                                  author_name: @user.name,
                                  color: @user.setting.brand_color1)
        @resource.update_column(:social_image, url)
        ## We only need to bust article. All else can fade naturally
        EdgeCache::BustArticle.call(@resource)
      elsif @resource.is_a?(User)
        @user = @resource
        read_files
        @resource.articles.published.where(organization_id: nil, main_image: nil).find_each do |article|
          url = generate_magickally(title: article.title,
                                    date: article.readable_publish_date,
                                    author_name: @user.name,
                                    color: @user.setting.brand_color1)
          article.update_column(:social_image, url)
        end
      else # Organization
        @user = @resource
        read_files
        @resource.articles.published.where(main_image: nil).find_each do |article|
          url = generate_magickally(title: article.title,
                                    date: article.readable_publish_date,
                                    author_name: @user.name,
                                    color: @user.bg_color_hex)
          article.update_column(:social_image, url)
        end
      end
    rescue StandardError => e
      Rails.logger.error(e)
      Honeybadger.notify(e)
    end

    private

    def generate_magickally(title: nil, date: nil, author_name: nil, color: nil)
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
        c.draw "rectangle 0,0 1000,24" # adjust width according to your image width
      end
    end

    def add_logo(result)
      if @logo_image
        # Add white stroke to the overlay image
        @logo_image.combine_options do |c|
          c.stroke "white"
          c.strokewidth "4"
          c.fill "none"
          c.draw "rectangle 0,0 1000,1000" # adjust as needed based on image size
        end

        # Resize the overlay image
        @logo_image.resize "64x64"

        result = @background_image.composite(@logo_image) do |c|
          c.compose "Over" # OverCompositeOp
          c.geometry "+850+372" # move the overlay to the top left
        end
      end
      result
    end

    def add_text(result, title, date, author_name)
      title = wrap_text(title)
      font_size = calculate_font_size(title)

      result.combine_options do |c|
        c.gravity "West" # Set the origin for the text at the top left corner
        c.pointsize font_size.to_s
        c.draw "text 80,-39 '#{title}'" # Start drawing text 90 from the left and slightly north
        c.fill "black"
        c.font BOLD_FONT_PATH.to_s
      end

      result.combine_options do |c|
        c.gravity "Southwest"
        c.pointsize "32"
        c.draw "text 156,88 '#{author_name}'" # adjust coordinates as needed
        c.fill "black"
        c.font MEDIUM_FONT_PATH.to_s
      end

      result.combine_options do |c|
        c.gravity "Southwest"
        c.pointsize "26"
        c.draw "text 156,60 '#{date}'" # adjust coordinates as needed
        c.fill "#525252"
      end
    end

    def add_profile_image(result)
      profile_image_size = "64x64"
      profile_image_location = "+80+63"
      # Add subtext and author image
      @author_image.resize profile_image_size
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
        88
      elsif text_length < 40
        77
      elsif text_length < 55
        65
      elsif text_length < 70
        60
      else
        50
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

    def read_files
      # These are files we can open once for all the images we are generating within the loop.
      @background_image = MiniMagick::Image.open(ActionController::Base.helpers.asset_path(TEMPLATE_PATH))
      @logo_image = MiniMagick::Image.open(@logo_url) if @logo_url.present?
      image = @user.profile_image_90
      author_image_url = image.start_with?("http") ? image : Images::Profile::BACKUP_LINK
      @author_image = MiniMagick::Image.open(author_image_url)
      @rounded_mask = MiniMagick::Image.open(ActionController::Base.helpers.asset_path(ROUNDED_MASK_PATH))
    end
  end
end
