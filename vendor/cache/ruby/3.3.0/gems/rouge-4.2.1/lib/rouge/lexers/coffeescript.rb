# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Coffeescript < RegexLexer
      tag 'coffeescript'
      aliases 'coffee', 'coffee-script'
      filenames '*.coffee', 'Cakefile'
      mimetypes 'text/coffeescript'

      title "CoffeeScript"
      desc 'The Coffeescript programming language (coffeescript.org)'

      def self.detect?(text)
        return true if text.shebang? 'coffee'
      end

      def self.keywords
        @keywords ||= Set.new %w(
          for by while until loop break continue return
          switch when then if else do yield throw try catch finally await
          new delete typeof instanceof super extends this class
          import export debugger
        )
      end

      def self.reserved
        @reserved ||= Set.new %w(
          case function var void with const let enum
          native implements interface package private protected public static
        )
      end

      def self.constants
        @constants ||= Set.new %w(
          true false yes no on off null NaN Infinity undefined
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          Array Boolean Date Error Function Math netscape Number Object
          Packages RegExp String sun decodeURI decodeURIComponent
          encodeURI encodeURIComponent eval isFinite isNaN parseFloat
          parseInt document window
        )
      end

      id = /[$a-zA-Z_][a-zA-Z0-9_]*/

      state :comments do
        rule %r/###[^#].*?###/m, Comment::Multiline
        rule %r/#.*$/, Comment::Single
      end

      state :whitespace do
        rule %r/\s+/m, Text
      end

      state :regex_comment do
        rule %r/^#(?!\{).*$/, Comment::Single
        rule %r/(\s+)(#(?!\{).*)$/ do
          groups Text, Comment::Single
        end
      end

      state :multiline_regex_begin do
        rule %r(///) do
          token Str::Regex
          goto :multiline_regex
        end
      end

      state :multiline_regex_end do
        rule %r(///([gimy]+\b|\B)), Str::Regex, :pop!
      end

      state :multiline_regex do
        mixin :multiline_regex_end
        mixin :regex_comment
        mixin :has_interpolation
        mixin :comments
        mixin :whitespace
        mixin :code_escape

        rule %r/\\\D/, Str::Escape
        rule %r/\\\d+/, Name::Variable
        rule %r/./m, Str::Regex
      end

      state :slash_starts_regex do
        mixin :comments
        mixin :whitespace
        mixin :multiline_regex_begin

        rule %r(
          /(\\.|[^\[/\\\n]|\[(\\.|[^\]\\\n])*\])+/ # a regex
          ([gimy]+\b|\B)
        )x, Str::Regex, :pop!

        rule(//) { pop! }
      end

      state :root do
        rule(%r(^(?=\s|/|<!--))) { push :slash_starts_regex }
        mixin :comments
        mixin :whitespace

        rule %r(
          [+][+]|--|~|&&|\band\b|\bor\b|\bis\b|\bisnt\b|\bnot\b|\bin\b|\bof\b|
          [?]|:|=|[|][|]|\\(?=\n)|(<<|>>>?|==?|!=?|[-<>+*`%&|^/])=?
        )x, Operator, :slash_starts_regex

        rule %r/[-=]>/, Name::Function

        rule %r/(@)([ \t]*)(#{id})/ do
          groups Name::Variable::Instance, Text, Name::Attribute
          push :slash_starts_regex
        end

        rule %r/([.])([ \t]*)(#{id})/ do
          groups Punctuation, Text, Name::Attribute
          push :slash_starts_regex
        end

        rule %r/#{id}(?=\s*:)/, Name::Attribute, :slash_starts_regex

        rule %r/#{id}/ do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.constants.include? m[0]
            token Name::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Other
          end

          push :slash_starts_regex
        end

        rule %r/[{(\[;,]/, Punctuation, :slash_starts_regex
        rule %r/[})\].]/, Punctuation

        rule %r/\d+[.]\d+([eE]\d+)?[fd]?/, Num::Float
        rule %r/0x[0-9a-fA-F]+/, Num::Hex
        rule %r/\d+/, Num::Integer
        rule %r/"""/, Str, :tdqs
        rule %r/'''/, Str, :tsqs
        rule %r/"/, Str, :dqs
        rule %r/'/, Str, :sqs
      end

      state :code_escape do
        rule %r(\\(
          c[A-Z]|
          x[0-9a-fA-F]{2}|
          u[0-9a-fA-F]{4}|
          u\{[0-9a-fA-F]{4}\}
        ))x, Str::Escape
      end

      state :strings do
        # all coffeescript strings are multi-line
        rule %r/[^#\\'"]+/m, Str
        mixin :code_escape
        rule %r/\\./, Str::Escape
        rule %r/#/, Str
      end

      state :double_strings do
        rule %r/'/, Str
        mixin :has_interpolation
        mixin :strings
      end

      state :single_strings do
        rule %r/"/, Str
        mixin :strings
      end

      state :interpolation do
        rule %r/}/, Str::Interpol, :pop!
        mixin :root
      end

      state :has_interpolation do
        rule %r/[#][{]/, Str::Interpol, :interpolation
      end

      state :dqs do
        rule %r/"/, Str, :pop!
        mixin :double_strings
      end

      state :tdqs do
        rule %r/"""/, Str, :pop!
        rule %r/"/, Str
        mixin :double_strings
      end

      state :sqs do
        rule %r/'/, Str, :pop!
        mixin :single_strings
      end

      state :tsqs do
        rule %r/'''/, Str, :pop!
        rule %r/'/, Str
        mixin :single_strings
      end
    end
  end
end
