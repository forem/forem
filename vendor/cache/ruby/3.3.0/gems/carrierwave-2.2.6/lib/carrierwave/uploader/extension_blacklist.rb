module CarrierWave
  module Uploader
    module ExtensionBlacklist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_extension_blacklist!
      end

      ##
      # Override this method in your uploader to provide a denylist of extensions which
      # are prohibited to be uploaded. Compares the file's extension case insensitive.
      # Furthermore, not only strings but Regexp are allowed as well.
      #
      # When using a Regexp in the denylist, `\A` and `\z` are automatically added to
      # the Regexp expression, also case insensitive.
      #
      # === Returns

      # [NilClass, String, Regexp, Array[String, Regexp]] a deny list of extensions which are prohibited to be uploaded
      #
      # === Examples
      #
      #     def extension_denylist
      #       %w(swf tiff)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def extension_denylist
      #       [/swf/, 'tiff']
      #     end
      #
      def extension_denylist
        if respond_to?(:extension_blacklist)
          ActiveSupport::Deprecation.warn "#extension_blacklist is deprecated, use #extension_denylist instead." unless instance_variable_defined?(:@extension_blacklist_warned)
          @extension_blacklist_warned = true
          extension_blacklist
        end
      end

    private

      def check_extension_blacklist!(new_file)
        return unless extension_denylist

        extension = new_file.extension.to_s
        if blacklisted_extension?(extension)
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.extension_blacklist_error", extension: new_file.extension.inspect,
                                                            prohibited_types: Array(extension_denylist).join(", "), default: :"errors.messages.extension_denylist_error")
        end
      end

      def blacklisted_extension?(extension)
        Array(extension_denylist).any? { |item| extension =~ /\A#{item}\z/i }
      end
    end
  end
end
