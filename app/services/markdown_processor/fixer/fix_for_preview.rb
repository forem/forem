module MarkdownProcessor
  module Fixer
    class FixForPreview < Base
      METHODS = %i[
        add_quotes_to_title
        add_quotes_to_description
        modify_hr_tags
        underscores_in_usernames
      ].freeze

      # #call is implemented in MarkdownProcessor::Fixer::base
    end
  end
end
