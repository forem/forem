require "rouge/plugins/redcarpet"

module Redcarpet
  module Render
    class HTMLRouge < HTML
      include Rouge::Plugins::Redcarpet

      # overrided method to add line number support
      def block_code(code, language, opts = {})
        lexer =
          begin
            # add fix to handle language with upper case
            Rouge::Lexer.find_fancy language.to_s.downcase, code
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
        return if %r{<a\s.+/a>}.match?(content)

        link_attributes = ""
        @options[:link_attributes]&.each do |attribute, value|
          link_attributes += %( #{attribute}="#{value}")
        end
        if (%r{https?://\S+}.match? link) || link.nil?
          %(<a href="#{link}"#{link_attributes}>#{content}</a>)
        elsif /\.{1}/.match? link
          %(<a href="//#{link}"#{link_attributes}>#{content}</a>)
        elsif link.start_with?("#")
          %(<a href="#{link}"#{link_attributes}>#{content}</a>)
        else
          %(<a href="#{app_protocol}#{app_domain}#{link}"#{link_attributes}>#{content}</a>)
        end
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

      def app_protocol
        ApplicationConfig["APP_PROTOCOL"]
      end

      def app_domain
        SiteConfig.app_domain
      end

      def slugify(string)
        stripped_string = ActionView::Base.full_sanitizer.sanitize string
        stripped_string.downcase.gsub(EmojiRegex::RGIEmoji, "").strip.gsub(/[[:punct:]]/u, "").gsub(/\s+/, "-")
      end
    end
  end
end
