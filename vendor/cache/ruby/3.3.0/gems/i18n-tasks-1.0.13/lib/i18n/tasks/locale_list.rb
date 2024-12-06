# frozen_string_literal: true

module I18n::Tasks
  module LocaleList
    module_function

    # @return locales converted to strings, with base locale first, the rest sorted alphabetically
    def normalize_locale_list(locales, base_locale, include_base = false)
      locales = Array(locales).map(&:to_s).sort
      if locales.include?(base_locale)
        [base_locale] + (locales - [base_locale])
      elsif include_base
        [base_locale] + locales
      else
        locales
      end
    end
  end
end
