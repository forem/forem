module Settings
  class General
    module Upsert
      PARAMS_TO_BE_CLEANED = %i[sidebar_tags suggested_tags suggested_users].freeze
      TAG_PARAMS = %w[sidebar_tags suggested_tags].freeze

      def self.call(settings)
        if settings[:logo].present?
          logo_uploader = upload_logo(settings[:logo])
          logo_settings = { original_logo: logo_uploader.url, resized_logo: logo_uploader.resized_logo.url }
        end

        cleaned_params = clean_params((logo_settings.nil? ? settings : settings.merge(logo_settings)).except(:logo))
        result = ::Settings::Upsert.call(cleaned_params, ::Settings::General)
        return result unless result.success?

        create_tags_if_necessary(settings)
        result
      end

      def self.clean_params(settings)
        PARAMS_TO_BE_CLEANED.each do |param|
          settings[param] = settings[param]&.downcase&.delete(" ") if settings[param]
        end
        settings[:credit_prices_in_cents]&.transform_values!(&:to_i)
        settings
      end

      # Bulk create tags if they should exist.
      # This is an acts-as-taggable-on as used on saving of an Article, etc.
      def self.create_tags_if_necessary(settings)
        return unless (settings.keys & TAG_PARAMS).any?

        tags = Settings::General.suggested_tags + Settings::General.sidebar_tags
        Tag.find_or_create_all_with_like_by_name(tags)
      end

      def self.upload_logo(image)
        LogoUploader.new.tap do |uploader|
          uploader.store!(image)
        end
      end
    end
  end
end
