# @forem/systems Force "public_url" even when fog_public is false via this monkeypatch
# Because we still want the "public" version path in all current scenarios.
# We also force this to use the SiteConfig instead of APP_DOMAIN because the value
# could change after initial boot.

if Rails.env.production?
  module CarrierWave
    module Storage
      class Fog < Abstract
        class File
          include CarrierWave::Utilities::Uri
          def url
            public_url.gsub(ApplicationConfig["APP_DOMAIN"], SiteConfig.app_domain)
          end
        end
      end
    end
  end
end
