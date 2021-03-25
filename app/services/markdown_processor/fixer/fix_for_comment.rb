module MarkdownProcessor
  module Fixer
    class FixForComment < Base
      METHODS = %i[
        modify_hr_tags
        underscores_in_usernames
      ].freeze
    end
  end
end
