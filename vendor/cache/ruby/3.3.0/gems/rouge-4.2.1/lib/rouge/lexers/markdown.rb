# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Markdown < RegexLexer
      title "Markdown"
      desc "Markdown, a light-weight markup language for authors"

      tag 'markdown'
      aliases 'md', 'mkd'
      filenames '*.markdown', '*.md', '*.mkd'
      mimetypes 'text/x-markdown'

      def html
        @html ||= HTML.new(options)
      end

      start { html.reset! }

      edot = /\\.|[^\\\n]/

      state :root do
        # YAML frontmatter
        rule(/\A(---\s*\n.*?\n?)^(---\s*$\n?)/m) { delegate YAML }

        rule %r/\\./, Str::Escape

        rule %r/^[\S ]+\n(?:---*)\n/, Generic::Heading
        rule %r/^[\S ]+\n(?:===*)\n/, Generic::Subheading

        rule %r/^#(?=[^#]).*?$/, Generic::Heading
        rule %r/^##*.*?$/, Generic::Subheading

        rule %r/^([ \t]*)(`{3,}|~{3,})([^\n]*\n)((.*?)(\n\1)(\2))?/m do |m|
          name = m[3].strip
          sublexer =
            begin
              Lexer.find_fancy(name.empty? ? "guess" : name, m[5], @options)
            rescue Guesser::Ambiguous => e
              e.alternatives.first.new(@options)
            end

          sublexer ||= PlainText.new(@options.merge(:token => Str::Backtick))
          sublexer.reset!

          token Text, m[1]
          token Punctuation, m[2]
          token Name::Label, m[3]
          if m[5]
            delegate sublexer, m[5]
          end

          token Text, m[6]

          if m[7]
            token Punctuation, m[7]
          else
            push do
              rule %r/^([ \t]*)(#{m[2]})/ do |mb|
                pop!
                token Text, mb[1]
                token Punctuation, mb[2]
              end
              rule %r/^.*\n/ do |mb|
                delegate sublexer, mb[1]
              end
            end
          end
        end

        rule %r/\n\n((    |\t).*?\n|\n)+/, Str::Backtick

        rule %r/(`+)(?:#{edot}|\n)+?\1/, Str::Backtick

        # various uses of * are in order of precedence

        # line breaks
        rule %r/^(\s*[*]){3,}\s*$/, Punctuation
        rule %r/^(\s*[-]){3,}\s*$/, Punctuation

        # bulleted lists
        rule %r/^\s*[*+-](?=\s)/, Punctuation

        # numbered lists
        rule %r/^\s*\d+\./, Punctuation

        # blockquotes
        rule %r/^\s*>.*?$/, Generic::Traceback

        # link references
        # [foo]: bar "baz"
        rule %r(^
          (\s*) # leading whitespace
          (\[) (#{edot}+?) (\]) # the reference
          (\s*) (:) # colon
        )x do
          groups Text, Punctuation, Str::Symbol, Punctuation, Text, Punctuation

          push :title
          push :url
        end

        # links and images
        rule %r/(!?\[)(#{edot}*?|[^\]]*?)(\])(?=[\[(])/ do
          groups Punctuation, Name::Variable, Punctuation
          push :link
        end

        rule %r/[*][*]#{edot}*?[*][*]/, Generic::Strong
        rule %r/__#{edot}*?__/, Generic::Strong

        rule %r/[*]#{edot}*?[*]/, Generic::Emph
        rule %r/_#{edot}*?_/, Generic::Emph

        # Automatic links
        rule %r/<.*?@.+[.].+>/, Name::Variable
        rule %r[<(https?|mailto|ftp)://#{edot}*?>], Name::Variable

        rule %r/[^\\`\[*\n&<]+/, Text

        # inline html
        rule(/&\S*;/) { delegate html }
        rule(/<#{edot}*?>/) { delegate html }
        rule %r/[&<]/, Text

        # An opening square bracket that is not a link
        rule %r/\[/, Text

        rule %r/\n/, Text
      end

      state :link do
        rule %r/(\[)(#{edot}*?)(\])/ do
          groups Punctuation, Str::Symbol, Punctuation
          pop!
        end

        rule %r/[(]/ do
          token Punctuation
          push :inline_title
          push :inline_url
        end

        rule %r/[ \t]+/, Text

        rule(//) { pop! }
      end

      state :url do
        rule %r/[ \t]+/, Text

        # the url
        rule %r/(<)(#{edot}*?)(>)/ do
          groups Name::Tag, Str::Other, Name::Tag
          pop!
        end

        rule %r/\S+/, Str::Other, :pop!
      end

      state :title do
        rule %r/"#{edot}*?"/, Name::Namespace
        rule %r/'#{edot}*?'/, Name::Namespace
        rule %r/[(]#{edot}*?[)]/, Name::Namespace
        rule %r/\s*(?=["'()])/, Text
        rule(//) { pop! }
      end

      state :inline_title do
        rule %r/[)]/, Punctuation, :pop!
        mixin :title
      end

      state :inline_url do
        rule %r/[^<\s)]+/, Str::Other, :pop!
        rule %r/\s+/m, Text
        mixin :url
      end
    end
  end
end
