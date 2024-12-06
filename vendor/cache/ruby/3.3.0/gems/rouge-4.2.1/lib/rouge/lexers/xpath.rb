# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class XPath < RegexLexer
      title 'XPath'
      desc 'XML Path Language (XPath) 3.1'
      tag 'xpath'
      filenames '*.xpath'

      # Terminal literals:
      # https://www.w3.org/TR/xpath-31/#terminal-symbols
      def self.digits
        @digits ||= %r/[0-9]+/
      end

      def self.decimalLiteral
        @decimalLiteral ||= %r/\.#{digits}|#{digits}\.[0-9]*/
      end

      def self.doubleLiteral
        @doubleLiteral ||= %r/(\.#{digits})|#{digits}(\.[0-9]*)?[eE][+-]?#{digits}/
      end

      def self.stringLiteral
        @stringLiteral ||= %r/("(("")|[^"])*")|('(('')|[^'])*')/
      end

      def self.ncName
        @ncName ||= %r/[a-z_][a-z_\-.0-9]*/i
      end

      def self.qName
        @qName ||= %r/(?:#{ncName})(?::#{ncName})?/
      end

      def self.uriQName
        @uriQName ||= %r/Q\{[^{}]*\}#{ncName}/
      end

      def self.eqName
        @eqName ||= %r/(?:#{uriQName}|#{qName})/
      end

      def self.commentStart
        @commentStart ||= %r/\(:/
      end

      def self.openParen
        @openParen ||= %r/\((?!:)/
      end

      # Terminal symbols:
      # https://www.w3.org/TR/xpath-30/#id-terminal-delimitation
      def self.kindTest
        @kindTest ||= Regexp.union %w(
          element attribute schema-element schema-attribute
          comment text node document-node namespace-node
        )
      end

      def self.kindTestForPI
        @kindTestForPI ||= Regexp.union %w(processing-instruction)
      end

      def self.axes
        @axes ||= Regexp.union %w(
          child descendant attribute self descendant-or-self
          following-sibling following namespace
          parent ancestor preceding-sibling preceding ancestor-or-self
        )
      end

      def self.operators
        @operators ||= Regexp.union %w(, => = := : >= >> > <= << < - * != + // / || |)
      end

      def self.keywords
        @keywords ||= Regexp.union %w(let for some every if then else return in satisfies)
      end

      def self.word_operators
        @word_operators ||= Regexp.union %w(
          and or eq ge gt le lt ne is
          div mod idiv
          intersect except union
          to
        )
      end

      def self.constructorTypes
        @constructorTypes ||= Regexp.union %w(function array map empty-sequence)
      end

      # Mixin states:

      state :commentsAndWhitespace do
        rule XPath.commentStart, Comment, :comment
        rule %r/\s+/m, Text::Whitespace
      end

      # Lexical states:
      # https://www.w3.org/TR/xquery-xpath-parsing/#XPath-lexical-states
      # https://lists.w3.org/Archives/Public/public-qt-comments/2004Aug/0127.html
      # https://www.w3.org/TR/xpath-30/#id-revision-log
      # https://www.w3.org/TR/xpath-31/#id-revision-log

      state :root do
        mixin :commentsAndWhitespace

        # Literals
        rule XPath.doubleLiteral, Num::Float
        rule XPath.decimalLiteral, Num::Float
        rule XPath.digits, Num
        rule XPath.stringLiteral, Literal::String

        # Variables
        rule %r/\$/, Name::Variable, :varname

        # Operators
        rule XPath.operators, Operator
        rule %r/#{XPath.word_operators}\b/, Operator::Word
        rule %r/#{XPath.keywords}\b/, Keyword
        rule %r/[?,{}()\[\]]/, Punctuation

        # Functions
        rule %r/(function)(\s*)(#{XPath.openParen})/ do # function declaration
          groups Keyword, Text::Whitespace, Punctuation
        end
        rule %r/(map|array|empty-sequence)/, Keyword # constructors
        rule %r/(#{XPath.kindTest})(\s*)(#{XPath.openParen})/ do  # kindtest
          groups Keyword, Text::Whitespace, Punctuation
          push :kindtest
        end
        rule %r/(#{XPath.kindTestForPI})(\s*)(#{XPath.openParen})/ do # processing instruction kindtest
          groups Keyword, Text::Whitespace, Punctuation
          push :kindtestforpi
        end
        rule %r/(#{XPath.eqName})(\s*)(#{XPath.openParen})/ do # function call
          groups Name::Function, Text::Whitespace, Punctuation
        end
        rule %r/(#{XPath.eqName})(\s*)(#)(\s*)(\d+)/ do # namedFunctionRef
          groups Name::Function, Text::Whitespace, Name::Function, Text::Whitespace, Name::Function
        end

        # Type commands
        rule %r/(cast|castable)(\s+)(as)/ do
          groups Keyword, Text::Whitespace, Keyword
          push :singletype
        end
        rule %r/(treat)(\s+)(as)/ do
          groups Keyword, Text::Whitespace, Keyword
          push :itemtype
        end
        rule %r/(instance)(\s+)(of)/ do
          groups Keyword, Text::Whitespace, Keyword
          push :itemtype
        end
        rule %r/(as)\b/ do
          token Keyword
          push :itemtype
        end

        # Paths
        rule %r/(#{XPath.ncName})(\s*)(:)(\s*)(\*)/ do
          groups Name::Tag, Text::Whitespace, Punctuation, Text::Whitespace, Operator
        end
        rule %r/(\*)(\s*)(:)(\s*)(#{XPath.ncName})/ do
          groups Operator, Text::Whitespace, Punctuation, Text::Whitespace, Name::Tag
        end
        rule %r/(#{XPath.axes})(\s*)(::)/ do
          groups Keyword, Text::Whitespace, Operator
        end
        rule %r/\.\.|\.|\*/, Operator
        rule %r/@/, Name::Attribute, :attrname
        rule XPath.eqName, Name::Tag
      end

      state :singletype do
        mixin :commentsAndWhitespace

        # Type name
        rule XPath.eqName do
          token Keyword::Type
          pop!
        end
      end

      state :itemtype do
        mixin :commentsAndWhitespace

        # Type tests
        rule %r/(#{XPath.kindTest})(\s*)(#{XPath.openParen})/ do
          groups Keyword::Type, Text::Whitespace, Punctuation
          # go to kindtest then occurrenceindicator
          goto :occurrenceindicator
          push :kindtest
        end
        rule %r/(#{XPath.kindTestForPI})(\s*)(#{XPath.openParen})/ do
          groups Keyword::Type, Text::Whitespace, Punctuation
          # go to kindtestforpi then occurrenceindicator
          goto :occurrenceindicator
          push :kindtestforpi
        end
        rule %r/(item)(\s*)(#{XPath.openParen})(\s*)(\))/ do
          groups Keyword::Type, Text::Whitespace, Punctuation, Text::Whitespace, Punctuation
          goto :occurrenceindicator
        end
        rule %r/(#{XPath.constructorTypes})(\s*)(#{XPath.openParen})/ do
          groups Keyword::Type, Text::Whitespace, Punctuation
        end

        # Type commands
        rule %r/(cast|castable)(\s+)(as)/ do
          groups Keyword, Text::Whitespace, Keyword
          goto :singletype
        end
        rule %r/(treat)(\s+)(as)/ do
          groups Keyword, Text::Whitespace, Keyword
          goto :itemtype
        end
        rule %r/(instance)(\s+)(of)/ do
          groups Keyword, Text::Whitespace, Keyword
          goto :itemtype
        end
        rule %r/(as)\b/, Keyword

        # Operators
        rule XPath.operators do
          token Operator
          pop!
        end
        rule %r/#{XPath.word_operators}\b/ do
          token Operator::Word
          pop!
        end
        rule %r/#{XPath.keywords}\b/ do
          token Keyword
          pop!
        end
        rule %r/[\[),]/ do
          token Punctuation
          pop!
        end

        # Other types (e.g. xs:double)
        rule XPath.eqName do
          token Keyword::Type
          goto :occurrenceindicator
        end
      end

      # For pseudo-parameters for the KindTest productions
      state :kindtest do
        mixin :commentsAndWhitespace

        # Pseudo-parameters:
        rule %r/[?*]/, Operator
        rule %r/,/, Punctuation
        rule %r/(element|schema-element)(\s*)(#{XPath.openParen})/ do
          groups Keyword::Type, Text::Whitespace, Punctuation
          push :kindtest
        end
        rule XPath.eqName, Name::Tag

        # End of pseudo-parameters
        rule %r/\)/, Punctuation, :pop!
      end

      # Similar to :kindtest, but recognizes NCNames instead of EQNames
      state :kindtestforpi do
        mixin :commentsAndWhitespace

        # Pseudo-parameters
        rule XPath.ncName, Name
        rule XPath.stringLiteral, Literal::String

        # End of pseudo-parameters
        rule %r/\)/, Punctuation, :pop!
      end

      state :occurrenceindicator do
        mixin :commentsAndWhitespace

        # Occurrence indicator
        rule %r/[?*+]/ do
          token Operator
          pop!
        end

        # Otherwise, lex it in root state:
        rule %r/(?![?*+])/ do
          pop!
        end
      end

      state :varname do
        mixin :commentsAndWhitespace

        # Function call
        rule %r/(#{XPath.eqName})(\s*)(#{XPath.openParen})/ do
          groups Name::Variable, Text::Whitespace, Punctuation
          pop!
        end

        # Variable name
        rule XPath.eqName, Name::Variable, :pop!
      end

      state :attrname do
        mixin :commentsAndWhitespace

        # Attribute name
        rule XPath.eqName, Name::Attribute, :pop!
        rule %r/\*/, Operator, :pop!
      end

      state :comment do
        # Comment end
        rule %r/:\)/, Comment, :pop!

        # Nested comment
        rule XPath.commentStart, Comment, :comment

        # Comment contents
        rule %r/[^:(]+/m, Comment
        rule %r/[:(]/, Comment
      end
    end
  end
end
