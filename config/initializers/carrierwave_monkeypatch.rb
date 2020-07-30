# @forem/systems Force "public_url" even when fog_public is false via this monkeypatch
# Because we still want the "public" version path in all current scenarios.

if Rails.env.production? && ENV["HEROKU_APP_ID"].blank?
  module CarrierWave
    module Storage
      class Fog < Abstract
        class File
          include CarrierWave::Utilities::Uri
          def url
            public_url
          end
        end
      end
    end
  end
end
