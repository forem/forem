module MarkdownProcessor
  module Fixer
    class FixForQuickShare < Base
      METHODS = %i[
        auto_embed_links
      ].freeze
    end
  end
end
