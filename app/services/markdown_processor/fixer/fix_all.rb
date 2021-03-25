module MarkdownProcessor
  module Fixer
    class FixAll < Base
      METHODS = %i[
        add_quotes_to_title
        add_quotes_to_description
        lowercase_published
        modify_hr_tags
        convert_new_lines
        split_tags
        underscores_in_usernames
      ].freeze
    end
  end
end
