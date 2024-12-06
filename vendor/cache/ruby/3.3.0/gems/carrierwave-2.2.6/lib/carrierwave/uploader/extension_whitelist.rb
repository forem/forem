module CarrierWave
  module Uploader
    module ExtensionWhitelist
      extend ActiveSupport::Concern

      included do
        before :cache, :check_extension_whitelist!
      end

      ##
      # Override this method in your uploader to provide an allowlist of extensions which
      # are allowed to be uploaded. Compares the file's extension case insensitive.
      # Furthermore, not only strings but Regexp are allowed as well.
      #
      # When using a Regexp in the allowlist, `\A` and `\z` are automatically added to
      # the Regexp expression, also case insensitive.
      #
      # === Returns
      #
      # [NilClass, String, Regexp, Array[String, Regexp]] an allowlist of extensions which are allowed to be uploaded
      #
      # === Examples
      #
      #     def extension_allowlist
      #       %w(jpg jpeg gif png)
      #     end
      #
      # Basically the same, but using a Regexp:
      #
      #     def extension_allowlist
      #       [/jpe?g/, 'gif', 'png']
      #     end
      #
      def extension_allowlist
        if respond_to?(:extension_whitelist)
          ActiveSupport::Deprecation.warn "#extension_whitelist is deprecated, use #extension_allowlist instead." unless instance_variable_defined?(:@extension_whitelist_warned)
          @extension_whitelist_warned = true
          extension_whitelist
        end
      end

    private

      def check_extension_whitelist!(new_file)
        return unless extension_allowlist

        extension = new_file.extension.to_s
        if !whitelisted_extension?(extension)
          # Look for whitelist first, then fallback to allowlist
          raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.extension_whitelist_error", extension: new_file.extension.inspect,
                                                            allowed_types: Array(extension_allowlist).join(", "), default: :"errors.messages.extension_allowlist_error")
        end
      end

      def whitelisted_extension?(extension)
        downcase_extension = extension.downcase
        Array(extension_allowlist).any? { |item| downcase_extension =~ /\A#{item}\z/i }
      end
    end # ExtensionWhitelist
  end # Uploader
end # CarrierWave
