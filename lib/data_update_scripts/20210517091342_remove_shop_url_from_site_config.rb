module DataUpdateScripts
  class RemoveShopUrlFromSiteConfig
    def run
      SiteConfig.delete_by(var: "shop_url")
    end
  end
end
