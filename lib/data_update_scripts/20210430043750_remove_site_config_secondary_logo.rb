module DataUpdateScripts
  class RemoveSiteConfigSecondaryLogo
    def run
      SiteConfig.destroy_by(var: "secondary_logo_url")
    end
  end
end
