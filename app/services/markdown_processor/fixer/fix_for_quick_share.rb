module MarkdownProcessor
  module Fixer
    class FixForQuickShare < Base
      METHODS = %i[
        auto_embed_links
      ].freeze

      def self.auto_embed_links(markdown)
        markdown = self.remove_embed_links(markdown)
        markdown = markdown.gsub(/(https?:\/\/(?!.*\.(jpg|jpeg|png|gif|pdf|docx))[^\s]+)/i, '{% embed \1 %}'+"\n\n");
      end

      def self.remove_embed_links(markdown)
        markdown = markdown.gsub(/(\{)(.*)(embed) ((https?|ftp):\/\/(\S*?\.\S*?))([\s)\[\]{},;"\':<]|\.\s|$)(.*)(\})/i, '\4');
      end
    end
  end
end
