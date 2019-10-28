require "rouge/plugins/redcarpet"

module Redcarpet
  module Render
    class HTMLRouge < HTML
      include Rouge::Plugins::Redcarpet

      # overrided method to add line number support
      def block_code(code, language, opts = {})
        lexer =
          begin
            Rouge::Lexer.find_fancy(language, code)
          rescue Rouge::Guesser::Ambiguous => e
            e.alternatives.first
          end
        lexer ||= Rouge::Lexers::PlainText

        # XXX HACK: Redcarpet strips hard tabs out of code blocks,
        # so we assume you're not using leading spaces that aren't tabs,
        # and just replace them here.
        if lexer.tag == "make"
          code.gsub! %r{^    }, "\t"
        end

        # append default css_class to block_code
        unless opts.key? "css_class"
          opts["css_class"] = "highlight #{lexer.tag}"
        end

        formatter = Rouge::Formatters::HTMLLegacy.new(opts)
        formatter.format(lexer.lex(code))
      end

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
