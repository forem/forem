module MarkdownProcessor
  module Fixer
    class FixForPreview < Base
      METHODS = %i[
        add_quotes_to_title
        add_quotes_to_description
        underscores_in_usernames
      ].freeze

      def self.call(markdown)
        return unless markdown

        ForemNative.fixer_fix_for_preview(markdown) || legacy_call(markdown)
      end
    end
  end
end
