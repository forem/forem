module MarkdownProcessor
  module Fixer
    class FixForComment < Base
      METHODS = %i[
        underscores_in_usernames
      ].freeze

      def self.call(markdown)
        return unless markdown

        ForemNative.fixer_fix_for_comment(markdown) || legacy_call(markdown)
      end
    end
  end
end
