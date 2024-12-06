# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Awk < RegexLexer
      title "Awk"
      desc "pattern-directed scanning and processing language"

      tag 'awk'
      filenames '*.awk'
      mimetypes 'application/x-awk'

      def self.detect?(text)
        return true if text.shebang?('awk')
      end

      id = /[$a-zA-Z_][a-zA-Z0-9_]*/

      def self.keywords
        @keywords ||= Set.new %w(
          if else while for do break continue return next nextfile delete
          exit print printf getline
        )
      end

      def self.declarations
        @declarations ||= Set.new %w(function)
      end

      def self.reserved
        @reserved ||= Set.new %w(BEGIN END)
      end

      def self.constants
        @constants ||= Set.new %w(
          CONVFMT FS NF NR FNR FILENAME RS OFS ORS OFMT SUBSEP ARGC ARGV
          ENVIRON
        )
      end

      def self.builtins
        @builtins ||= %w(
          exp log sqrt sin cos atan2 length rand srand int substr index match
          split sub gsub sprintf system tolower toupper
        )
      end

      state :comments_and_whitespace do
        rule %r/\s+/, Text
        rule %r(#.*?$), Comment::Single
      end

      state :expr_start do
        mixin :comments_and_whitespace
        rule %r(/) do
          token Str::Regex
          goto :regex
        end
        rule %r//, Text, :pop!
      end

      state :regex do
        rule %r(/) do
          token Str::Regex
          goto :regex_end
        end

        rule %r([^/]\n), Error, :pop!

        rule %r/\n/, Error, :pop!
        rule %r/\[\^/, Str::Escape, :regex_group
        rule %r/\[/, Str::Escape, :regex_group
        rule %r/\\./, Str::Escape
        rule %r{[(][?][:=<!]}, Str::Escape
        rule %r/[{][\d,]+[}]/, Str::Escape
        rule %r/[()?]/, Str::Escape
        rule %r/./, Str::Regex
      end

      state :regex_end do
        rule(//) { pop! }
      end

      state :regex_group do
        # specially highlight / in a group to indicate that it doesn't
        # close the regex
        rule %r(/), Str::Escape

        rule %r([^/]\n) do
          token Error
          pop! 2
        end

        rule %r/\]/, Str::Escape, :pop!
        rule %r/\\./, Str::Escape
        rule %r/./, Str::Regex
      end

      state :bad_regex do
        rule %r/[^\n]+/, Error, :pop!
      end

      state :root do
        mixin :comments_and_whitespace
        rule %r((?<=\n)(?=\s|/)), Text, :expr_start
        rule %r([-<>+*/%\^!=]=?|in\b|\+\+|--|\|), Operator, :expr_start
        rule %r(&&|\|\||~!?), Operator, :expr_start
        rule %r/[(\[,]/, Punctuation, :expr_start
        rule %r/;/, Punctuation, :statement
        rule %r/[)\].]/, Punctuation

        rule %r/[?]/ do
          token Punctuation
          push :ternary
          push :expr_start
        end

        rule %r/[{}]/, Punctuation, :statement

        rule id do |m|
          if self.class.keywords.include? m[0]
            token Keyword
            push :expr_start
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
            push :expr_start
          elsif self.class.reserved.include? m[0]
            token Keyword::Reserved
          elsif self.class.constants.include? m[0]
            token Keyword::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          elsif m[0] =~ /^\$/
            token Name::Variable
          else
            token Name::Other
          end
        end

        rule %r/[0-9]+\.[0-9]+/, Num::Float
        rule %r/[0-9]+/, Num::Integer
        rule %r/"(\\[\\"]|[^"])*"/, Str::Double
        rule %r/:/, Punctuation
      end

      state :statement do
        rule %r/[{}]/, Punctuation
        mixin :expr_start
      end

      state :ternary do
        rule %r/:/ do
          token Punctuation
          goto :expr_start
        end

        mixin :root
      end
    end
  end
end
