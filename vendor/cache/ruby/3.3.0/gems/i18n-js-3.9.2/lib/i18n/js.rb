require "yaml"
require "fileutils"
require "i18n"

require "i18n/js/utils"
require "i18n/js/private/hash_with_symbol_keys"
require "i18n/js/private/config_store"

module I18n
  module JS
    require "i18n/js/dependencies"
    require "i18n/js/fallback_locales"
    require "i18n/js/segment"
    if JS::Dependencies.rails?
      require "i18n/js/middleware"
      require "i18n/js/engine"
    end

    DEFAULT_CONFIG_PATH = "config/i18n-js.yml"
    DEFAULT_EXPORT_DIR_PATH = "public/javascripts"

    # The configuration file. This defaults to the `config/i18n-js.yml` file.
    #
    def self.config_file_path
      @config_file_path ||= DEFAULT_CONFIG_PATH
    end

    def self.config_file_path=(new_path)
      @config_file_path = new_path
      # new config file path = need to re-read config from new file
      Private::ConfigStore.instance.flush_cache
    end

    # Allow using a different backend than the one globally configured
    def self.backend
      @backend ||= I18n.backend
    end

    def self.backend=(alternative_backend)
      @backend = alternative_backend
    end

    # Export translations to JavaScript, considering settings
    # from configuration file
    def self.export
      export_i18n_js

      translation_segments.each(&:save!)
    end

    def self.segment_for_scope(scope, exceptions)
      if scope == "*"
        exclude(translations, exceptions)
      else
        scoped_translations(scope, exceptions)
      end
    end

    def self.configured_segments
      config[:translations].inject([]) do |segments, options_hash|
        options_hash_with_symbol_keys = Private::HashWithSymbolKeys.new(options_hash)
        file = options_hash_with_symbol_keys[:file]
        only = options_hash_with_symbol_keys[:only] || '*'
        exceptions = [options_hash_with_symbol_keys[:except] || []].flatten

        result = segment_for_scope(only, exceptions)

        merge_with_fallbacks!(result) if fallbacks

        unless result.empty?
          segments << Segment.new(
            file,
            result,
            extract_segment_options(options_hash_with_symbol_keys),
          )
        end

        segments
      end
    end

    # deep_merge! given result with result for fallback locale
    def self.merge_with_fallbacks!(result)
      js_available_locales.each do |locale|
        fallback_locales = FallbackLocales.new(fallbacks, locale)
        fallback_locales.each do |fallback_locale|
          # `result[fallback_locale]` could be missing
          result[locale] = Utils.deep_merge(result[fallback_locale] || {}, result[locale] || {})
        end
      end
    end

    def self.filtered_translations
      translations = {}.tap do |result|
        translation_segments.each do |segment|
          Utils.deep_merge!(result, segment.translations)
        end
      end
      return Utils.deep_key_sort(translations) if I18n::JS.sort_translation_keys?
      translations
    end

    def self.translation_segments
      if config_file_exists? && config[:translations]
        configured_segments
      else
        [Segment.new("#{DEFAULT_EXPORT_DIR_PATH}/translations.js", translations)]
      end
    end

    # Load configuration file for partial exporting and
    # custom output directory
    def self.config
      Private::ConfigStore.instance.fetch do
        if config_file_exists?
          erb_result_from_yaml_file = ERB.new(File.read(config_file_path)).result
          Private::HashWithSymbolKeys.new(
            (::YAML.load(erb_result_from_yaml_file) || {})
          )
        else
          Private::HashWithSymbolKeys.new({})
        end.freeze
      end
    end

    # @api private
    # Check if configuration file exist
    def self.config_file_exists?
      File.file? config_file_path
    end

    def self.scoped_translations(scopes, exceptions = []) # :nodoc:
      result = {}

      [scopes].flatten.each do |scope|
        translations_without_exceptions = exclude(translations, exceptions)
        filtered_translations = filter(translations_without_exceptions, scope) || {}

        Utils.deep_merge!(result, filtered_translations)
      end

      result
    end

    # Exclude keys from translations listed in the `except:` section in the config file
    def self.exclude(translations, exceptions)
      return translations if exceptions.empty?

      exceptions.inject(translations) do |memo, exception|
        exception_scopes = exception.to_s.split(".")
        Utils.deep_reject(memo) do |key, value, scopes|
          Utils.scopes_match?(scopes, exception_scopes)
        end
      end
    end

    # Filter translations according to the specified scope.
    def self.filter(translations, scopes)
      scopes = scopes.split(".") if scopes.is_a?(String)
      scopes = scopes.clone
      scope = scopes.shift

      if scope == "*"
        results = {}
        translations.each do |scope, translations|
          tmp = scopes.empty? ? translations : filter(translations, scopes)
          results[scope.to_sym] = tmp unless tmp.nil?
        end
        return results
      elsif translations.respond_to?(:key?) && translations.key?(scope.to_sym)
        return {scope.to_sym => scopes.empty? ? translations[scope.to_sym] : filter(translations[scope.to_sym], scopes)}
      end
      nil
    end

    # Initialize and return translations
    def self.translations
      self.backend.instance_eval do
        init_translations unless initialized?
        # When activesupport is absent,
        # the core extension (`#slice`) from `i18n` gem will be used instead
        # And it's causing errors (at least in test)
        #
        # So the input is wrapped by our class for better `#slice`
        Private::HashWithSymbolKeys.new(translations).
          slice(*::I18n::JS.js_available_locales).
          to_h
      end
    end

    def self.use_fallbacks?
      fallbacks != false
    end

    def self.json_only
      config.fetch(:json_only) do
        # default value
        false
      end
    end

    def self.fallbacks
      config.fetch(:fallbacks) do
        # default value
        true
      end
    end

    def self.js_extend
      config.fetch(:js_extend) do
        # default value
        true
      end
    end

    # Get all available locales.
    #
    # @return [Array<Symbol>] the locales.
    def self.js_available_locales
      config.fetch(:js_available_locales) do
        # default value
        I18n.available_locales
      end.map(&:to_sym)
    end

    def self.sort_translation_keys?
      @sort_translation_keys ||= (config[:sort_translation_keys]) if config.key?(:sort_translation_keys)
      @sort_translation_keys = true if @sort_translation_keys.nil?
      @sort_translation_keys
    end

    def self.sort_translation_keys=(value)
      @sort_translation_keys = !!value
    end

    def self.extract_segment_options(options)
      segment_options = Private::HashWithSymbolKeys.new({
        js_extend: js_extend,
        sort_translation_keys: sort_translation_keys?,
        json_only: json_only
      }).freeze
      segment_options.merge(options.slice(*Segment::OPTIONS))
    end

    ### Export i18n.js
    begin

      # Copy i18n.js
      def self.export_i18n_js
        return unless export_i18n_js_dir_path.is_a? String

        FileUtils.mkdir_p(export_i18n_js_dir_path)

        i18n_js_path = File.expand_path('../../../app/assets/javascripts/i18n.js', __FILE__)
        destination_path = File.expand_path("i18n.js", export_i18n_js_dir_path)
        return if File.exist?(destination_path) && FileUtils.identical?(i18n_js_path, destination_path)

        FileUtils.cp(i18n_js_path, export_i18n_js_dir_path)
      end

      def self.export_i18n_js_dir_path
        @export_i18n_js_dir_path ||= (config[:export_i18n_js] || :none) if config.key?(:export_i18n_js)
        @export_i18n_js_dir_path ||= DEFAULT_EXPORT_DIR_PATH
        @export_i18n_js_dir_path
      end

      # Setting this to nil would disable i18n.js exporting
      def self.export_i18n_js_dir_path=(new_path)
        new_path = :none unless new_path.is_a? String
        @export_i18n_js_dir_path = new_path
      end
    end
  end
end
