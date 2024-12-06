# -*- coding: utf-8 #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Scala < RegexLexer
      title "Scala"
      desc "The Scala programming language (scala-lang.org)"
      tag 'scala'
      aliases 'scala'
      filenames '*.scala', '*.sbt'

      mimetypes 'text/x-scala', 'application/x-scala'

      # As documented in the ENBF section of the scala specification
      # https://scala-lang.org/files/archive/spec/2.13/13-syntax-summary.html
      # https://en.wikipedia.org/wiki/Unicode_character_property#General_Category
      whitespace = /\p{Space}/
      letter = /[\p{L}$_]/
      upper = /[\p{Lu}$_]/
      digits = /[0-9]/
      parens = /[(){}\[\]]/
      delims = %r([‘’".;,])

      # negative lookahead to filter out other classes
      op = %r(
        (?!#{whitespace}|#{letter}|#{digits}|#{parens}|#{delims})
        [-!#%&*/:?@\\^\p{Sm}\p{So}]
      )x
      # manually removed +<=>|~ from regexp because they're in property Sm
      # pp CHRS:(0x00..0x7f).map(&:chr).grep(/\p{Sm}/)

      idrest = %r(#{letter}(?:#{letter}|#{digits})*(?:(?<=_)#{op}+)?)x

      keywords = %w(
        abstract case catch def do else extends final finally for forSome
        if implicit lazy match new override private protected requires return
        sealed super this throw try val var while with yield
      )

      state :root do
        rule %r/(class|trait|object)(\s+)/ do
          groups Keyword, Text
          push :class
        end
        rule %r/'#{idrest}(?!')/, Str::Symbol
        rule %r/[^\S\n]+/, Text

        rule %r(//.*), Comment::Single
        rule %r(/\*), Comment::Multiline, :comment

        rule %r/@#{idrest}/, Name::Decorator

        rule %r/(def)(\s+)(#{idrest}|#{op}+|`[^`]+`)(\s*)/ do
          groups Keyword, Text, Name::Function, Text
        end

        rule %r/(val)(\s+)(#{idrest}|#{op}+|`[^`]+`)(\s*)/ do
          groups Keyword, Text, Name::Variable, Text
        end

        rule %r/(this)(\n*)(\.)(#{idrest})/ do
          groups Keyword, Text, Operator, Name::Property
        end

        rule %r/(#{idrest}|_)(\n*)(\.)(#{idrest})/ do
          groups Name::Variable, Text, Operator, Name::Property
        end

        rule %r/#{upper}#{idrest}\b/, Name::Class

        rule %r/(#{idrest})(#{whitespace}*)(\()/ do
          groups Name::Function, Text, Operator
        end

        rule %r/(\.)(#{idrest})/ do
          groups Operator, Name::Property
        end

        rule %r(
          (#{keywords.join("|")})\b|
          (<[%:-]|=>|>:|[#=@_\u21D2\u2190])(\b|(?=\s)|$)
        )x, Keyword
        rule %r/:(?!#{op})/, Keyword, :type
        rule %r/(true|false|null)\b/, Keyword::Constant
        rule %r/(import|package)(\s+)/ do
          groups Keyword, Text
          push :import
        end

        rule %r/(type)(\s+)/ do
          groups Keyword, Text
          push :type
        end

        rule %r/""".*?"""(?!")/m, Str
        rule %r/"(\\\\|\\"|[^"])*"/, Str
        rule %r/'\\.'|'[^\\]'|'\\u[0-9a-fA-F]{4}'/, Str::Char

        rule idrest, Name
        rule %r/`[^`]+`/, Name

        rule %r/\[/, Operator, :typeparam
        rule %r/[\(\)\{\};,.#]/, Operator
        rule %r/#{op}+/, Operator

        rule %r/([0-9][0-9]*\.[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?[fFdD]?/, Num::Float
        rule %r/([0-9][0-9]*[fFdD])/, Num::Float
        rule %r/0x[0-9a-fA-F]+/, Num::Hex
        rule %r/[0-9]+L?/, Num::Integer
        rule %r/\n/, Text
      end

      state :class do
        rule %r/(#{idrest}|#{op}+|`[^`]+`)(\s*)(\[)/ do
          groups Name::Class, Text, Operator
          push :typeparam
        end

        rule %r/\s+/, Text
        rule %r/{/, Operator, :pop!
        rule %r/\(/, Operator, :pop!
        rule %r(//.*), Comment::Single, :pop!
        rule %r(#{idrest}|#{op}+|`[^`]+`), Name::Class, :pop!
      end

      state :type do
        rule %r/\s+/, Text
        rule %r/<[%:]|>:|[#_\u21D2]|forSome|type/, Keyword
        rule %r/([,\);}]|=>|=)(\s*)/ do
          groups Operator, Text
          pop!
        end
        rule %r/[\(\{]/, Operator, :type

        typechunk = /(?:#{idrest}|#{op}+\`[^`]+`)/
        rule %r/(#{typechunk}(?:\.#{typechunk})*)(\s*)(\[)/ do
          groups Keyword::Type, Text, Operator
          pop!
          push :typeparam
        end

        rule %r/(#{typechunk}(?:\.#{typechunk})*)(\s*)$/ do
          groups Keyword::Type, Text
          pop!
        end

        rule %r(//.*), Comment::Single, :pop!
        rule %r/\.|#{idrest}|#{op}+|`[^`]+`/, Keyword::Type
      end

      state :typeparam do
        rule %r/[\s,]+/, Text
        rule %r/<[%:]|=>|>:|[#_\u21D2]|forSome|type/, Keyword
        rule %r/([\]\)\}])/, Operator, :pop!
        rule %r/[\(\[\{]/, Operator, :typeparam
        rule %r/\.|#{idrest}|#{op}+|`[^`]+`/, Keyword::Type
      end

      state :comment do
        rule %r([^/\*]+), Comment::Multiline
        rule %r(/\*), Comment::Multiline, :comment
        rule %r(\*/), Comment::Multiline, :pop!
        rule %r([*/]), Comment::Multiline
      end

      state :import do
        rule %r((#{idrest}|\.)+), Name::Namespace, :pop!
      end
    end
  end
end
