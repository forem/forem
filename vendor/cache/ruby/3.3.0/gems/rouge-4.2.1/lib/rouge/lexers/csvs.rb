# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class CSVS < RegexLexer
      tag 'csvs'
      title "csvs"
      desc 'The CSV Schema Language (digital-preservation.github.io)'
      filenames '*.csvs'

      state :root do
        rule %r/\s+/m, Text

        rule %r(//[\S\t ]*), Comment::Single
        rule %r(/\*[^*]*\*/)m, Comment::Multiline

        rule %r/(version)( )(\d+\.\d+)/ do
          groups Keyword, Text::Whitespace, Num::Float
        end

        rule %r/T?\d{2}:\d{2}:\d{2}(\.\d{5})?(Z|(?:[-+]\d{2}:\d{2}))?/, Literal::Date
        rule %r/\d{4}-\d{2}-\d{2}/, Literal::Date
        rule %r/\d{2}\/\d{2}\/\d{4}/, Literal::Date

        rule %r((\d+[.]?\d*|\d*[.]\d+)(e[+-]?[0-9]+)?)i, Num::Float
        rule %r/\d+/, Num::Integer

        rule %r/@\w+/, Keyword::Pseudo

        rule %r/[-.\w]+:/, Name::Variable
        rule %r/^"[^"]+"/, Name::Variable
        rule %r/\$([-.\w]+|("[^"]+"))\/?/, Name::Variable

        rule %r/[A-Z]+/i, Keyword

        rule %r/"[^"]*"/, Str::Double
        rule %r/'[^\r\n\f']'/, Str::Char

        rule %r/[,()*]/, Punctuation
      end
    end
  end
end
