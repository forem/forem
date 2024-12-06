require "i18n/js/private/hash_with_symbol_keys"
require "i18n/js/formatters/js"
require "i18n/js/formatters/json"

module I18n
  module JS

    # Class which enscapulates a translations hash and outputs a single JSON translation file
    class Segment
      OPTIONS = [:namespace, :pretty_print, :js_extend, :prefix, :suffix, :sort_translation_keys, :json_only].freeze
      LOCALE_INTERPOLATOR = /%\{locale\}/

      attr_reader *([:file, :translations] | OPTIONS)

      def initialize(file, translations, options = {})
        @file         = file
        # `#slice` will be used
        # But when activesupport is absent,
        # the core extension from `i18n` gem will be used instead
        # And it's causing errors (at least in test)
        #
        # So the input is wrapped by our class for better `#slice`
        @translations = Private::HashWithSymbolKeys.new(translations)
        @namespace    = options[:namespace] || 'I18n'
        @pretty_print = !!options[:pretty_print]
        @js_extend    = options.key?(:js_extend) ? !!options[:js_extend] : true
        @prefix       = options.key?(:prefix) ? options[:prefix] : nil
        @suffix       = options.key?(:suffix) ? options[:suffix] : nil
        @sort_translation_keys = options.key?(:sort_translation_keys) ? !!options[:sort_translation_keys] : true
        @json_only = options.key?(:json_only) ? !!options[:json_only] : false
      end

      # Saves JSON file containing translations
      def save!
        if @file =~ LOCALE_INTERPOLATOR
          I18n::JS.js_available_locales.each do |locale|
            write_file(file_for_locale(locale), @translations.slice(locale))
          end
        else
          write_file
        end
      end

      protected

      def file_for_locale(locale)
        @file.gsub(LOCALE_INTERPOLATOR, locale.to_s)
      end

      def write_file(_file = @file, _translations = @translations)
        FileUtils.mkdir_p File.dirname(_file)
        _translations = Utils.deep_key_sort(_translations) if @sort_translation_keys
        _translations = Utils.deep_remove_procs(_translations)
        contents = formatter.format(_translations)

        return if File.exist?(_file) && File.read(_file) == contents

        File.open(_file, "w+") do |f|
          f << contents
        end
      end

      def formatter
        if @json_only
          Formatters::JSON.new(**formatter_options)
        else
          Formatters::JS.new(**formatter_options)
        end
      end

      def formatter_options
        { js_extend: @js_extend,
          namespace: @namespace,
          pretty_print: @pretty_print,
          prefix: @prefix,
          suffix: @suffix
        }
      end
    end
  end
end
