# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class LiterateHaskell < RegexLexer
      title "Literate Haskell"
      desc 'Literate haskell'
      tag 'literate_haskell'
      aliases 'lithaskell', 'lhaskell', 'lhs'
      filenames '*.lhs'
      mimetypes 'text/x-literate-haskell'

      def haskell
        @haskell ||= Haskell.new(options)
      end

      start { haskell.reset! }

      # TODO: support TeX versions as well.
      state :root do
        rule %r/\s*?\n(?=>)/, Text, :code
        rule %r/.*?\n/, Text
        rule %r/.+\z/, Text
      end

      state :code do
        rule %r/(>)( .*?(\n|\z))/ do |m|
          token Name::Label, m[1]
          delegate haskell, m[2]
        end

        rule %r/\s*\n(?=\s*[^>])/, Text, :pop!
      end
    end
  end
end
