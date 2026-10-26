# @forem/systems Force "public_url" even when fog_public is false via this monkeypatch
# Because we still want the "public" version path in all current scenarios.
# We also force this to use the Settings::General instead of APP_DOMAIN because the value
# could change after initial boot.

module CarrierWave
  module Storage
    class Fog < Abstract
      class File
        include CarrierWave::Utilities::Uri
        def url(*args)
          public_url.gsub(ApplicationConfig["APP_DOMAIN"], Settings::General.app_domain)
        end

        # Avoid triggering a synchronous S3 HEAD request (`#empty?` -> `#exists?` -> `directory.files.head(path)`)
        # when ActiveSupport's `Object#blank?` / `#present?` is called on a stored Fog::File.
        delegate :blank?, to: :path

        # Restore CarrierWave 2.x `#copy_to` behavior (`connection.copy_object` directly).
        # CarrierWave 3.x changed this to `file.copy(...)`, which in `fog-aws` executes `copy_object`
        # followed by an unconditional `target_directory.files.head(target_file_key)` S3 HEAD request
        # whose return value is immediately discarded.
        def copy_to(new_path)
          connection.copy_object(@uploader.fog_directory, path, @uploader.fog_directory, new_path, copy_options)
          CarrierWave::Storage::Fog::File.new(@uploader, @base, new_path)
        end
      end
    end
  end
end
