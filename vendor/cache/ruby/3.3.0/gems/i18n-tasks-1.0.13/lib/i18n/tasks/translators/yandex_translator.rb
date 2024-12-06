# frozen_string_literal: true

require 'i18n/tasks/translators/base_translator'

module I18n::Tasks::Translators
  class YandexTranslator < BaseTranslator
    def initialize(*)
      begin
        require 'yandex-translator'
      rescue LoadError
        raise ::I18n::Tasks::CommandError, "Add gem 'yandex-translator' to your Gemfile to use this command"
      end
      super
    end

    protected

    def translate_values(list, **options)
      list.map { |item| translator.translate(item, options) }
    end

    def options_for_translate_values(from:, to:, **options)
      options.merge(
        from: to_yandex_compatible_locale(from),
        to: to_yandex_compatible_locale(to)
      )
    end

    def options_for_html
      { format: 'html' }
    end

    def options_for_plain
      { format: 'plain' }
    end

    def no_results_error_message
      I18n.t('i18n_tasks.yandex_translate.errors.no_results')
    end

    private

    # Convert 'es-ES' to 'es'
    def to_yandex_compatible_locale(locale)
      return locale unless locale.include?('-')

      locale.split('-', 2).first
    end

    def translator
      @translator ||= Yandex::Translator.new(api_key)
    end

    def api_key
      @api_key ||= begin
        key = @i18n_tasks.translation_config[:yandex_api_key]
        fail ::I18n::Tasks::CommandError, I18n.t('i18n_tasks.yandex_translate.errors.no_api_key') if key.blank?

        key
      end
    end
  end
end
