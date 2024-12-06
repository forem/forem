# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'javascript.rb'

    class JSX < Javascript
      title 'JSX'
      desc 'An XML-like syntax extension to JavaScript (facebook.github.io/jsx/)'
      tag 'jsx'
      aliases 'jsx', 'react'
      filenames '*.jsx'

      mimetypes 'text/x-jsx', 'application/x-jsx'

      start { @html = HTML.new(options); push :expr_start }

      prepend :expr_start do
        mixin :tag
      end

      state :tag do
        rule %r/</ do
          token Punctuation
          push :tag_opening
          push :element
          push :element_name
        end
      end

      state :tag_opening do
        rule %r/<\// do
          token Punctuation
          goto :element
          push :element_name
        end
        mixin :tag
        rule %r/{/ do
          token Str::Interpol
          push :interpol
          push :expr_start
        end
        rule %r/[^<{]+/ do
          delegate @html
        end
      end

      state :element do
        mixin :comments_and_whitespace
        rule %r/\/>/ do
          token Punctuation
          pop! 2
        end
        rule %r/>/, Punctuation, :pop!
        rule %r/{/ do
          token Str::Interpol
          push :interpol
          push :expr_start
        end
        rule %r/\w[\w-]*/, Name::Attribute
        rule %r/=/, Punctuation
        rule %r/(["']).*?(\1)/, Str
      end

      state :element_name do
        rule %r/[A-Z]\w*/, Name::Class
        rule %r/\w+/, Name::Tag
        rule %r/\./, Punctuation
        rule(//) { pop! }
      end

      state :interpol do
        rule %r/}/, Str::Interpol, :pop!
        rule %r/{/ do
          token Punctuation
          push :interpol_inner
          push :statement
        end
        mixin :root
      end

      state :interpol_inner do
        rule %r/}/ do
          token Punctuation
          goto :statement
        end
        mixin :root
      end
    end
  end
end
