module CarrierWave
  module Uploader
    module ContentTypeBlacklist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_content_type_blacklist!
      end

      ##
      # Override this method in your uploader to provide a denylist of files content types
      # which are not allowed to be uploaded.
      # Not only strings but Regexp are allowed as well.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] a denylist of content types which are not allowed to be uploaded
      #
      # === Examples
      #
      #     def content_type_denylist
      #       %w(text/json application/json)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def content_type_denylist
      #       [/(text|application)\/json/]
      #     end
      #
      def content_type_denylist
        if respond_to?(:content_type_blacklist)
          ActiveSupport::Deprecation.warn "#content_type_blacklist is deprecated, use #content_type_denylist instead." unless instance_variable_defined?(:@content_type_blacklist_warned)
          @content_type_blacklist_warned = true
          content_type_blacklist
        end
      end

    private

      def check_content_type_blacklist!(new_file)
        return unless content_type_denylist

        content_type = new_file.content_type
        if blacklisted_content_type?(content_type)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_blacklist_error",
                                                            content_type: content_type, default: :"errors.messages.content_type_denylist_error")
        end
      end

      def blacklisted_content_type?(content_type)
        Array(content_type_denylist).any? { |item| content_type =~ /#{item}/ }
      end

    end # ContentTypeBlacklist
  end # Uploader
end # CarrierWave
