# frozen_string_literal: true

require 'i18n/tasks/translators/deepl_translator'
require 'i18n/tasks/translators/google_translator'
require 'i18n/tasks/translators/openai_translator'
require 'i18n/tasks/translators/yandex_translator'

module I18n::Tasks
  module Translation
    # @param [I18n::Tasks::Tree::Siblings] forest to translate to the locales of its root nodes
    # @param [String] from locale
    # @param [:deepl, :openai, :google, :yandex] backend
    # @return [I18n::Tasks::Tree::Siblings] translated forest
    def translate_forest(forest, from:, backend: :google)
      case backend
      when :deepl
        Translators::DeeplTranslator.new(self).translate_forest(forest, from)
      when :google
        Translators::GoogleTranslator.new(self).translate_forest(forest, from)
      when :openai
        Translators::OpenAiTranslator.new(self).translate_forest(forest, from)
      when :yandex
        Translators::YandexTranslator.new(self).translate_forest(forest, from)
      else
        fail CommandError, "invalid backend: #{backend}"
      end
    end
  end
end
