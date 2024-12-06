module CarrierWave
  module Uploader
    module ContentTypeWhitelist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_whitelist!
      end

      ##
      # Override this method in your uploader to provide an allowlist of files content types
      # which are allowed to be uploaded.
      # Not only strings but Regexp are allowed as well.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] an allowlist of content types which are allowed to be uploaded
      #
      # === Examples
      #
      #     def content_type_allowlist
      #       %w(text/json application/json)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def content_type_allowlist
      #       [/(text|application)\/json/]
      #     end
      #
      def content_type_allowlist
        if respond_to?(:content_type_whitelist)
          ActiveSupport::Deprecation.warn "#content_type_whitelist is deprecated, use #content_type_allowlist instead." unless instance_variable_defined?(:@content_type_whitelist_warned)
          @content_type_whitelist_warned = true
          content_type_whitelist
        end
      end

    private

      def check_content_type_whitelist!(new_file)
        return unless content_type_allowlist

        content_type = new_file.content_type
        if !whitelisted_content_type?(content_type)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_whitelist_error", content_type: content_type,
                                                            allowed_types: Array(content_type_allowlist).join(", "), default: :"errors.messages.content_type_allowlist_error")
        end
      end

      def whitelisted_content_type?(content_type)
        Array(content_type_allowlist).any? do |item|
          item = Regexp.quote(item) if item.class != Regexp
          content_type =~ /\A#{item}/
        end
      end

    end # ContentTypeWhitelist
  end # Uploader
end # CarrierWave
