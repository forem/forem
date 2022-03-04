# @forem/systems Force "public_url" even when fog_public is false via this monkeypatch
# Because we still want the "public" version path in all current scenarios.
# We also force this to use the Settings::General instead of APP_DOMAIN because the value
# could change after initial boot.

module CarrierWave
  module Storage
    class Fog < Abstract
      class File
        include CarrierWave::Utilities::Uri
        def url
          public_url.gsub(ApplicationConfig["APP_DOMAIN"], Settings::General.app_domain)
        end
      end
    end
  end
end
