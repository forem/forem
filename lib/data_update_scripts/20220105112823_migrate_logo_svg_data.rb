module DataUpdateScripts
  class MigrateLogoSvgData
    def run
      return if ::Settings::General.try(:logo_svg).blank? ||
        (::Settings::General.try(:original_logo).present? && ::Settings::General.try(:resized_logo).present?)

      Tempfile.create(["logo", ".svg"]) do |file|
        file.write(::Settings::General.logo_svg)

        logo_svg_uploader = LogoSvgUploader.new.tap do |uploader|
          uploader.store!(file)
        end

        ::Settings::General.original_logo = logo_svg_uploader.url
        ::Settings::General.resized_logo = logo_svg_uploader.resized_logo.url
      end
    rescue StandardError => e
      # If we can't convert the logo, then alert ourselves so that we can track the Forems
      # whose logos could not be converted.

      Rails.logger.error("Could not convert logo_svg for #{Settings::Community.community_name} Forem to a PNG.")

      Honeybadger.notify(e, context: {
                           community_name: Settings::Community.community_name,
                           app_domain: Settings::General.app_domain,
                           tags: "failed_svg_conversion"
                         })
    end
  end
end
