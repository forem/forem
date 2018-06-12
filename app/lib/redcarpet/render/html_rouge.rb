require "rouge/plugins/redcarpet"

module Redcarpet
  module Render
    class HTMLRouge < HTML
      include Rouge::Plugins::Redcarpet

      def link(link, _title, content)
        # Probably not the best fix but it does it's job of preventing
        # a nested links.
        return nil if /<a\s.+\/a>/.match?(content)
        %(<a href="#{link}">#{content}</a>)
      end
    end
  end
end
