# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class TeX < RegexLexer
      title "TeX"
      desc "The TeX typesetting system"
      tag 'tex'
      aliases 'TeX', 'LaTeX', 'latex'

      filenames '*.tex', '*.aux', '*.toc', '*.sty', '*.cls'
      mimetypes 'text/x-tex', 'text/x-latex'

      def self.detect?(text)
        return true if text =~ /\A\s*\\(documentclass|input|documentstyle|relax|ProvidesPackage|ProvidesClass)/
      end

      command = /\\([a-z]+|\s+|.)/i

      state :general do
        rule %r/%.*$/, Comment
        rule %r/[{}&_^]/, Punctuation
      end

      state :root do
        rule %r/\\\[/, Punctuation, :displaymath
        rule %r/\\\(/, Punctuation, :inlinemath
        rule %r/\$\$/, Punctuation, :displaymath
        rule %r/\$/, Punctuation, :inlinemath
        rule %r/\\(begin|end)\{.*?\}/, Name::Tag

        rule %r/(\\verb)\b(\S)(.*?)(\2)/ do
          groups Name::Builtin, Keyword::Pseudo, Str::Other, Keyword::Pseudo
        end

        rule command, Keyword, :command
        mixin :general
        rule %r/[^\\$%&_^{}]+/, Text
      end

      state :math do
        rule command, Name::Variable
        mixin :general
        rule %r/[0-9]+/, Num
        rule %r/[-=!+*\/()\[\]]/, Operator
        rule %r/[^=!+*\/()\[\]\\$%&_^{}0-9-]+/, Name::Builtin
      end

      state :inlinemath do
        rule %r/\\\)/, Punctuation, :pop!
        rule %r/\$/, Punctuation, :pop!
        mixin :math
      end

      state :displaymath do
        rule %r/\\\]/, Punctuation, :pop!
        rule %r/\$\$/, Punctuation, :pop!
        rule %r/\$/, Name::Builtin
        mixin :math
      end

      state :command do
        rule %r/\[.*?\]/, Name::Attribute
        rule %r/\*/, Keyword
        rule(//) { pop! }
      end
    end
  end
end
