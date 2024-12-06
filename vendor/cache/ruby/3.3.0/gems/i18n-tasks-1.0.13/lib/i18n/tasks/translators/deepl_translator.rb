# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'

module I18n::Tasks::Translators
  class DeeplTranslator < BaseTranslator
    # max allowed texts per request
    BATCH_SIZE = 50
    # those languages must be specified with their sub-kind e.g en-us
    SPECIFIC_TARGETS = %w[en pt].freeze

    def initialize(*)
      begin
        require 'deepl'
      rescue LoadError
        raise ::I18n::Tasks::CommandError, "Add gem 'deepl-rb' to your Gemfile to use this command"
      end
      super
      configure_api_key!
    end

    protected

    def translate_values(list, from:, to:, **options)
      results = []
      list.each_slice(BATCH_SIZE) do |parts|
        res = DeepL.translate(parts, to_deepl_source_locale(from), to_deepl_target_locale(to), options)
        if res.is_a?(DeepL::Resources::Text)
          results << res.text
        else
          results += res.map(&:text)
        end
      end
      results
    end

    def options_for_translate_values(**options)
      extra_options = @i18n_tasks.translation_config[:deepl_options]&.symbolize_keys || {}

      extra_options.merge({ ignore_tags: %w[i18n] }).merge(options)
    end

    def options_for_html
      { tag_handling: 'xml' }
    end

    def options_for_plain
      { preserve_formatting: true, tag_handling: 'xml', html_escape: true }
    end

    # @param [String] value
    # @return [String] 'hello, %{name}' => 'hello, <i18n>%{name}</i18n>'
    def replace_interpolations(value)
      value.gsub(INTERPOLATION_KEY_RE, '<i18n>\0</i18n>')
    end

    # @param [String] untranslated
    # @param [String] translated
    # @return [String] 'hello, <i18n>%{name}</i18n>' => 'hello, %{name}'
    def restore_interpolations(untranslated, translated)
      return translated if untranslated !~ INTERPOLATION_KEY_RE

      translated.gsub(%r{</?i18n>}, '')
    rescue StandardError => e
      raise_interpolation_error(untranslated, translated, e)
    end

    def no_results_error_message
      I18n.t('i18n_tasks.deepl_translate.errors.no_results')
    end

    private

    # Convert 'es-ES' to 'ES', en-us to EN
    def to_deepl_source_locale(locale)
      locale.to_s.split('-', 2).first.upcase
    end

    # Convert 'es-ES' to 'ES' but warn about locales requiring a specific variant
    def to_deepl_target_locale(locale)
      loc, sub = locale.to_s.split('-')
      if SPECIFIC_TARGETS.include?(loc)
        # Must see how the deepl api evolves, so this could be an error in the future
        warn_deprecated I18n.t('i18n_tasks.deepl_translate.errors.specific_target_missing') unless sub
        locale.to_s.upcase
      else
        loc.upcase
      end
    end

    def configure_api_key!
      api_key = @i18n_tasks.translation_config[:deepl_api_key]
      host = @i18n_tasks.translation_config[:deepl_host]
      version = @i18n_tasks.translation_config[:deepl_version]
      fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.deepl_translate.errors.no_api_key') if api_key.blank?

      DeepL.configure do |config|
        config.auth_key = api_key
        config.host = host unless host.blank?
        config.version = version unless version.blank?
      end
    end
  end
end
