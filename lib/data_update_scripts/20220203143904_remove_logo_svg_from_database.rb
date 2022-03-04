module DataUpdateScripts
  class RemoveLogoSvgFromDatabase
    def run
      Settings::General.destroy_by(var: :logo_svg)
    end
  end
end
