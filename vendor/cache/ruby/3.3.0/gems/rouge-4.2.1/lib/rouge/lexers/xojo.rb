# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Xojo < RegexLexer
      title "Xojo"
      desc "Xojo"
      tag 'xojo'
      aliases 'realbasic'
      filenames '*.xojo_code', '*.xojo_window', '*.xojo_toolbar', '*.xojo_menu', '*.xojo_image', '*.rbbas', '*.rbfrm', '*.rbmnu', '*.rbres', '*.rbtbar'

      keywords = %w(
          addhandler aggregates array asc assigns attributes begin break
          byref byval call case catch class const continue color ctype declare
          delegate dim do downto each else elseif end enum event exception
          exit extends false finally for function global goto if
          implements inherits interface lib loop mod module
          new next nil object of optional paramarray
          private property protected public raise raiseevent rect redim
          removehandler return select shared soft static step sub super
          then to true try until using var wend while
        )

      keywords_type = %w(
          boolean byte cfstringref cgfloat cstring currency date datetime double int8 int16
          int32 int64 integer ostype pair pstring ptr short single
          string structure variant uinteger uint8 uint16 uint32 uint64
          ushort windowptr wstring
        )

      operator_words = %w(
          addressof weakaddressof and as in is isa mod not or xor
        )

      state :root do
        rule %r/\s+/, Text::Whitespace

        rule %r/rem\b.*?$/i, Comment::Single
        rule %r((?://|').*$), Comment::Single
        rule %r/\#tag Note.*?\#tag EndNote/mi, Comment::Preproc
        rule %r/\s*[#].*$/x, Comment::Preproc

        rule %r/".*?"/, Literal::String::Double
        rule %r/[(){}!#,:]/, Punctuation

        rule %r/\b(?:#{keywords.join('|')})\b/i, Keyword
        rule %r/\b(?:#{keywords_type.join('|')})\b/i, Keyword::Declaration

        rule %r/\b(?:#{operator_words.join('|')})\b/i, Operator
        rule %r/[+-]?(\d+\.\d*|\d*\.\d+)/i, Literal::Number::Float
        rule %r/[+-]?\d+/, Literal::Number::Integer
        rule %r/&[CH][0-9a-f]+/i, Literal::Number::Hex
        rule %r/&O[0-7]+/i, Literal::Number::Oct

        rule %r/\b[\w\.]+\b/i, Text
        rule(%r(<=|>=|<>|[=><\+\-\*\/\\]), Operator)
      end
    end
  end
end
