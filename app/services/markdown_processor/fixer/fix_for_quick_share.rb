module MarkdownProcessor
  module Fixer
    class FixForQuickShare < Base
      METHODS = %i[
        auto_embed_links
      ].freeze

      def self.auto_embed_links(markdown)
        markdown = markdown.gsub(/(\{)(.*)(embed) ((https?|ftp):\/\/(\S*?\.\S*?))([\s)\[\]{},;"\':<]|\.\s|$)(.*)(\})/i, '\4');
        markdown = markdown.gsub(/((https?|ftp):\/\/(\S*?\.\S*?))([\s)\[\]{},;"\':<]|\.\s|$)/i, '{% embed \1 %}'+"\n\n");
      end
    end
  end
end
