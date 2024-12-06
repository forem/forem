# frozen_string_literal: true

module I18n::Tasks
  module HtmlKeys
    HTML_KEY_PATTERN = /[.\-_]html\z/.freeze
    MAYBE_PLURAL_HTML_KEY_PATTERN = /[.\-_]html\.[^.]+\z/.freeze

    def html_key?(full_key, locale)
      !!(full_key =~ HTML_KEY_PATTERN ||
          (full_key =~ MAYBE_PLURAL_HTML_KEY_PATTERN &&
              depluralize_key(split_key(full_key, 2)[1], locale) =~ HTML_KEY_PATTERN))
    end
  end
end
