module Settings
  class General
    module Upsert
      PARAMS_TO_BE_CLEANED = %i[sidebar_tags suggested_tags].freeze
      TAG_PARAMS = %w[sidebar_tags suggested_tags].freeze

      def self.call(settings)
        params_to_clean = settings.except(:logo)

        if settings[:logo].present?
          logo_uploader = upload_logo(settings[:logo])
          logo_settings = { original_logo: logo_uploader.url, resized_logo: logo_uploader.resized_logo.url }
          params_to_clean = params_to_clean.merge(logo_settings)
        end

        cleaned_params = clean_params(params_to_clean)
        anonymous_tracking_geos = ::Settings::General.geos_with_allowed_anonymous_tracking
        result = ::Settings::Upsert.call(cleaned_params, ::Settings::General)
        return result unless result.success?

        create_tags_if_necessary(settings)
        if ::Settings::General.geos_with_allowed_anonymous_tracking != anonymous_tracking_geos
          purge_billboard_responses
        end
        result
      end

      # Billboard responses tell browsers whether their region allows anonymous tracking, so
      # cached ones must go when the allowed regions change, or a removed region would keep
      # getting the go-ahead until they expire.
      def self.purge_billboard_responses
        EdgeCache::PurgeByKey.call(BillboardPlacementAreaConfig::RESPONSES_SURROGATE_KEY)
      end

      def self.clean_params(settings)
        PARAMS_TO_BE_CLEANED.each do |param|
          settings[param] = settings[param]&.downcase&.delete(" ") if settings[param]
        end
        settings[:credit_prices_in_cents]&.transform_values!(&:to_i)
        settings[:billboard_enabled_countries]&.transform_values!(&:to_sym)
        settings
      end

      # Bulk create tags if they should exist.
      # This is an acts-as-taggable-on as used on saving of an Article, etc.
      def self.create_tags_if_necessary(settings)
        return unless (settings.keys & TAG_PARAMS).any?

        create_sidebar_tags
        create_suggested_tags
      end

      def self.create_sidebar_tags
        Tag.find_or_create_all_with_like_by_name(Settings::General.sidebar_tags)
      end

      def self.create_suggested_tags
        suggested = Tag.find_or_create_all_with_like_by_name(Settings::General.suggested_tags)
        Tag.where(suggested: true).update_all(suggested: false)
        Tag.where(id: suggested).update_all(suggested: true)
      end

      def self.upload_logo(image)
        LogoUploader.new.tap do |uploader|
          uploader.store!(image)
        end
      end

      private_class_method :upload_logo
    end
  end
end
