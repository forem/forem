require 'active_model'
require 'active_support/i18n'
require 'public_suffix'
I18n.load_path += Dir[File.dirname(__FILE__) + "/locale/*.yml"]

module ActiveModel
  module Validations
    class UrlValidator < ActiveModel::EachValidator
      RESERVED_OPTIONS = [:schemes, :no_local]

      def initialize(options)
        options.reverse_merge!(schemes: %w(http https))
        options.reverse_merge!(message: :url)
        options.reverse_merge!(no_local: false)
        options.reverse_merge!(public_suffix: false)
        options.reverse_merge!(accept_array: false)

        super(options)
      end

      def validate_each(record, attribute, value)
        schemes = [*options.fetch(:schemes)].map(&:to_s)
        if value.respond_to?(:each)
          # Error out if we're not allowing arrays
          if !options.include?(:accept_array) || !options.fetch(:accept_array)
            record.errors.add(attribute, :url, **filtered_options(value))
          end

          # We have to manually handle `:allow_nil` and `:allow_blank` since it's not caught by
          # ActiveRecord's own validators. We do that by just removing all the nil's if we want to
          # allow them so it's not passed on later.
          value = value.reject(&:nil?) if options.include?(:allow_nil) && options.fetch(:allow_nil)
          value = value.reject(&:blank?) if options.include?(:allow_blank) && options.fetch(:allow_blank)

          result = value.flat_map { |v| validate_url(record, attribute, v, schemes) }
          errors = result.reject(&:nil?)

          return errors.any? ? errors.first : true
        end

        validate_url(record, attribute, value, schemes)
      end

      protected

      def filtered_options(value)
        filtered = options.except(*RESERVED_OPTIONS)
        filtered[:value] = value
        filtered
      end

      def validate_url(record, attribute, value, schemes)
        uri = URI.parse(value)
        host = uri && uri.host
        scheme = uri && uri.scheme

        valid_raw_url = scheme && value =~ /\A#{URI::regexp([scheme])}\z/
        valid_scheme = host && scheme && schemes.include?(scheme)
        valid_no_local = !options.fetch(:no_local) || (host && host.include?('.'))
        valid_suffix = !options.fetch(:public_suffix) || (host && PublicSuffix.valid?(host, :default_rule => nil))

        unless valid_raw_url && valid_scheme && valid_no_local && valid_suffix
          record.errors.add(attribute, options.fetch(:message), value: value)
        end
      rescue URI::InvalidURIError, URI::InvalidComponentError
        record.errors.add(attribute, :url, **filtered_options(value))
      end
    end

    module ClassMethods
      # Validates whether the value of the specified attribute is valid url.
      #
      #   class Unicorn
      #     include ActiveModel::Validations
      #     attr_accessor :homepage, :ftpsite
      #     validates_url :homepage, allow_blank: true
      #     validates_url :ftpsite, schemes: ['ftp']
      #   end
      # Configuration options:
      # * <tt>:message</tt> - A custom error message (default is: "is not a valid URL").
      # * <tt>:allow_nil</tt> - If set to true, skips this validation if the attribute is +nil+ (default is +false+).
      # * <tt>:allow_blank</tt> - If set to true, skips this validation if the attribute is blank (default is +false+).
      # * <tt>:schemes</tt> - Array of URI schemes to validate against. (default is +['http', 'https']+)

      def validates_url(*attr_names)
        validates_with UrlValidator, _merge_attributes(attr_names)
      end
    end
  end
end
