module MarkdownProcessor
  module Fixer
    class FixForComment < Base
      METHODS = %i[
        underscores_in_usernames
      ].freeze
    end
  end
end
