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
        url = generate_magickally(
          title: @resource.title,
          date: @resource.readable_publish_date,
          author_name: @user.name,
          color: @user.setting.brand_color1
        )
        @resource.update_column(:social_image, url)
      elsif @resource.is_a?(User)
        @user = @resource
        read_files
        @resource.articles.published.where(organization_id: nil, main_image: nil).find_each do |article|
          url = generate_magickally(title: article.title,
            date: article.readable_publish_date,
            author_name: @user.name,
            color: @user.setting.brand_color1
          )
          article.update_column(:social_image, url)
        end
      else # Organization
        @user = @resource
        read_files
        @resource.articles.published.where(main_image: nil).find_each do |article|
          url = generate_magickally(title: article.title,
            date: article.readable_publish_date,
            author_name: @user.name,
            color: @user.bg_color_hex
          )
          article.update_column(:social_image, url)
        end
      end
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
      @background_image.combine_options do |c|
        c.fill color
        c.draw "rectangle 0,0 1000,24"
      end
    end

    def add_logo(result)
      return result unless @logo_image

      # Add white stroke to the overlay image
      @logo_image.combine_options do |c|
        c.stroke "white"
        c.strokewidth "4"
        c.fill "none"
        c.draw "rectangle 0,0 1000,1000"
      end

      # Resize the overlay image
      @logo_image.resize "64x64"

      result.composite(@logo_image) do |c|
        c.compose "Over" # OverCompositeOp
        c.geometry "+850+372"
      end
    end

    def add_text(result, title, date, author_name)
      title = wrap_text(title)
      font_size = calculate_font_size(title)

      result.combine_options do |c|
        c.gravity "West"
        c.pointsize font_size.to_s
        c.draw "..."
      end
    end

    def read_files
      # These are files we can open once for all the images we are generating within the loop.
      @background_image = MiniMagick::Image.open(ActionController::Base.helpers.asset_path(TEMPLATE_PATH))
      @logo_image = MiniMagick::Image.open(@logo_url) if @logo_url.present?
      author_image_url = @user.profile_image_90.start_with?("http") ? @user.profile_image_90 : Images::Profile::BACKUP_LINK
      @author_image = MiniMagick::Image.open(author_image_url)
      @rounded_mask = MiniMagick::Image.open(ActionController::Base.helpers.asset_path(ROUNDED_MASK_PATH))
    end  
  end
end
