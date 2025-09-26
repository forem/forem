module Images
  TEMPLATE_PATH = "app/assets/images/social_template.png".freeze

  class GenerateSubforemImages
    def self.call(subforem_id, image_url, background_url = nil)
      new(subforem_id, image_url, background_url).call
    end

    def initialize(subforem_id, image_url, background_url = nil)
      @subforem_id = subforem_id
      @image_url = image_url
      @background_url = background_url
      @subforem = Subforem.find(subforem_id)
    end

    def call
      generate_resized_logo
      generate_favicon
      generate_main_social_image
      generate_logo_png
    rescue StandardError => e
      Rails.logger.error("Failed to generate subforem images: #{e.message}")
      Honeybadger.notify(e) if defined?(Honeybadger)
    end

    private

    def generate_resized_logo
      resized_url = resize_image(@image_url, 100, 100)
      Settings::General.set_resized_logo(resized_url, subforem_id: @subforem_id)
    rescue StandardError => e
      Rails.logger.error("Failed to generate resized logo: #{e.message}")
    end

    def generate_favicon
      favicon_url = resize_image(@image_url, 100, 100)
      Settings::General.set_favicon_url(favicon_url, subforem_id: @subforem_id)
    rescue StandardError => e
      Rails.logger.error("Failed to generate favicon: #{e.message}")
    end

    def generate_logo_png
      logo_url = resize_image(@image_url, 512, 512)
      Settings::General.set_logo_png(logo_url, subforem_id: @subforem_id)
    rescue StandardError => e
      Rails.logger.error("Failed to generate logo png: #{e.message}")
    end

    def generate_main_social_image
      social_image_url = create_social_image
      Settings::General.set_main_social_image(social_image_url, subforem_id: @subforem_id)
    rescue StandardError => e
      Rails.logger.error("Failed to generate main social image: #{e.message}")
    end

    def resize_image(source_url, width, height)
      # Download the source image
      source_image = MiniMagick::Image.open(source_url)

      # Resize the image
      source_image.resize "#{width}x#{height}"

      # Upload the resized image
      upload_image(source_image)
    end

    def create_social_image
      # Use background URL if provided, otherwise use the existing social template
      if @background_url.present?
        background = MiniMagick::Image.open(@background_url)
        # Crop the background to exactly 1000x500, centered
        background.combine_options do |c|
          c.resize "1000x500^" # Resize to cover the area (may be larger)
          c.gravity "Center"     # Center the image
          c.extent "1000x500"    # Crop to exact dimensions
        end
      else
        background = MiniMagick::Image.open(TEMPLATE_PATH)
      end

      # Download and resize the source image to 300x300
      source_image = MiniMagick::Image.open(@image_url)
      source_image.resize "300x300"

      # Calculate position to center the image (1000-300)/2 = 350, (500-300)/2 = 100
      x_position = 350
      y_position = 100

      # Composite the source image onto the background
      result = background.composite(source_image) do |c|
        c.compose "Over"
        c.geometry "+#{x_position}+#{y_position}"
      end

      # Upload the result
      upload_image(result)
    end

    def upload_image(image)
      # Create a temporary file
      tempfile = Tempfile.new(["subforem_image", ".png"])
      image.write tempfile.path

      # Upload using ArticleImageUploader
      image_uploader = ArticleImageUploader.new.tap do |uploader|
        uploader.store!(tempfile)
      end

      # Clean up the tempfile
      tempfile.close
      tempfile.unlink

      # Return the uploaded URL
      image_uploader.url
    end
  end
end
