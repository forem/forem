module DataUpdateScripts
  class MigrateLogoSvgData
    def run
      return if ::Settings::General.try(:logo_svg).blank? ||
        (::Settings::General.try(:original_logo).present? && ::Settings::General.try(:resized_logo).present?)

      temp_svg = Tempfile.new(["logo", ".svg"])
      temp_svg.write(::Settings::General.logo_svg)
      temp_svg.close

      logo_svg_uploader = LogoSvgUploader.new.tap do |uploader|
        uploader.store!(temp_svg)
      end

      ::Settings::General.original_logo = logo_svg_uploader.url
      ::Settings::General.resized_logo = logo_svg_uploader.resized_logo.url
    rescue StandardError => e
      # If we can't convert the logo, then alert ourselves so that we can track the Forems
      # whose logos could not be converted
      Rails.logger.error("Could not convert logo_svg for #{Settings::Community.community_name} Forem to a PNG")
      Honeybadger.notify(e)
      ForemStatsClient.increment("logo_svg.conversion")
    end
  end
end
