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
    end
  end
end
