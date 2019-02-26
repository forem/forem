require "rouge/plugins/redcarpet"

module Redcarpet
  module Render
    class HTMLRouge < HTML
      include Rouge::Plugins::Redcarpet

      def link(link, _title, content)
        # Probably not the best fix but it does it's job of preventing
        # a nested links.
        return nil if /<a\s.+\/a>/.match?(content)

        link_attributes = ""
        @options[:link_attributes]&.each do |attribute, value|
          link_attributes += %( #{attribute}="#{value}")
        end
        %(<a href="#{link}"#{link_attributes}>#{content}</a>)
      end

      def header(title, header_number)
        anchor_link = slugify(title)
        <<~HEREDOC
          <h#{header_number}>
            <a name="#{anchor_link}" href="##{anchor_link}" class="anchor">
            </a>
            #{title}
          </h#{header_number}>
        HEREDOC
      end

      private

      def slugify(string)
        stripped_string = ActionView::Base.full_sanitizer.sanitize string
        stripped_string.downcase.gsub(EmojiRegex::Regex, "").strip.gsub(/[[:punct:]]/u, "").gsub(/\s+/, "-")
      end
    end
  end
end
