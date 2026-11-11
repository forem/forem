require "open-uri"

module Images
  class GenerateSubforemImages
    TEMPLATE_PATH = "app/assets/images/social_template.png".freeze
    DEFAULT_FONT_PATH = Rails.root.join("app/assets/fonts/NotoSans-Bold.ttf").to_s.freeze

    def self.call(subforem_id, image_url, background_url = nil)
      new(subforem_id, image_url, background_url).call
    end

    def initialize(subforem_id, image_url, background_url = nil)
      @subforem_id = subforem_id
      @image_url = image_url
      @background_url = background_url
      @subforem = Subforem.find(subforem_id)
      @source_bytes_cache = {}
    end

    def call
      generate_resized_logo
      generate_favicon
      generate_main_social_image
      generate_logo_png
    rescue StandardError => e
      Rails.logger.error("Failed to generate subforem images: #{e.message}")
      Rails.error.report(e)
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
      source_bytes = fetch_image_bytes(source_url)
      png_bytes = ForemNative.subforem_resize_png(
        source_bytes,
        width,
        height,
        font_path: DEFAULT_FONT_PATH,
      )
      upload_image(png_bytes)
    end

    def create_social_image
      custom_background = @background_url.present?
      background_bytes = fetch_image_bytes(custom_background ? @background_url : TEMPLATE_PATH)
      logo_bytes = fetch_image_bytes(@image_url)
      png_bytes = ForemNative.subforem_social_image_png(
        logo_bytes,
        background_bytes,
        custom_background: custom_background,
        font_path: DEFAULT_FONT_PATH,
      )
      upload_image(png_bytes)
    end

    def fetch_image_bytes(source)
      @source_bytes_cache[source] ||= read_image_bytes(source)
    end

    def read_image_bytes(source)
      str = source.to_s
      if str.match?(%r{\Ahttps?://}i)
        URI.parse(str).open("rb", &:read).b
      else
        File.binread(str)
      end
    end

    def upload_image(png_bytes)
      tempfile = Tempfile.new(["subforem_image", ".png"])
      begin
        File.binwrite(tempfile.path, png_bytes)
        image_uploader = ArticleImageUploader.new.tap do |uploader|
          uploader.store!(tempfile)
        end
        image_uploader.url
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end
end
