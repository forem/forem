module DataUpdateScripts
  class MigrateLogoSvgData
    def run
      return if ::Settings::General.try(:logo_svg).blank?

      temp_svg = Tempfile.new(["logo", ".svg"])
      temp_svg.write(logo_svg)
      temp_svg.close

      logo_svg_uploader = LogoSVGUploader.new.tap do |uploader|
        uploader.store!(temp_svg)
      end

      ::Settings::General.original_logo = logo_svg_uploader.url
      ::Settings::General.resized_logo = logo_svg_uploader.resized_logo.url

      # svg_string = '<svg xmlns="http://www.w3.org/2000/svg"
      # width="120" height="120" viewPort="0 0 120 120" version="1.1">
      # <rect width="150" height="150" fill="rgb(0, 255, 0)" stroke-width="1" stroke="rgb(0, 0, 0)" />
      # <line x1="20" y1="100" x2="100" y2="20" stroke="black" stroke-width="2"/>
      # </svg>'
    end
  end
end
