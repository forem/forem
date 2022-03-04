module MarkdownProcessor
  module Fixer
    class FixForPreview < Base
      METHODS = %i[
        add_quotes_to_title
        add_quotes_to_description
        underscores_in_usernames
      ].freeze
    end
  end
end
