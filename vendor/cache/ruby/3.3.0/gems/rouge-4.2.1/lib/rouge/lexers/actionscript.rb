# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Actionscript < RegexLexer
      title "ActionScript"
      desc "ActionScript"

      tag 'actionscript'
      aliases 'as', 'as3'
      filenames '*.as'
      mimetypes 'application/x-actionscript'

      state :comments_and_whitespace do
        rule %r/\s+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/\*.*?\*/)m, Comment::Multiline
      end

      state :expr_start do
        mixin :comments_and_whitespace

        rule %r(/) do
          token Str::Regex
          goto :regex
        end

        rule %r/[{]/, Punctuation, :object

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
        rule %r/[gim]+/, Str::Regex, :pop!
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

      def self.keywords
        @keywords ||= Set.new %w(
          for in while do break return continue switch case default
          if else throw try catch finally new delete typeof is
          this with
        )
      end

      def self.declarations
        @declarations ||= Set.new %w(var with function)
      end

      def self.reserved
        @reserved ||= Set.new %w(
          dynamic final internal native public protected private class const
          override static package interface extends implements namespace
          set get import include super flash_proxy object_proxy trace
        )
      end

      def self.constants
        @constants ||= Set.new %w(true false null NaN Infinity undefined)
      end

      def self.builtins
        @builtins ||= %w(
          void Function Math Class
          Object RegExp decodeURI
          decodeURIComponent encodeURI encodeURIComponent
          eval isFinite isNaN parseFloat parseInt this
        )
      end

      id = /[$a-zA-Z_][a-zA-Z0-9_]*/

      state :root do
        rule %r/\A\s*#!.*?\n/m, Comment::Preproc, :statement
        rule %r/\n/, Text, :statement
        rule %r((?<=\n)(?=\s|/|<!--)), Text, :expr_start
        mixin :comments_and_whitespace
        rule %r(\+\+ | -- | ~ | && | \|\| | \\(?=\n) | << | >>>? | ===
               | !== )x,
          Operator, :expr_start
        rule %r([:-<>+*%&|\^/!=]=?), Operator, :expr_start
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
          else
            token Name::Other
          end
        end

        rule %r/\-?[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?/, Num::Float
        rule %r/0x[0-9a-fA-F]+/, Num::Hex
        rule %r/\-?[0-9]+/, Num::Integer
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Double
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Single
      end

      # braced parts that aren't object literals
      state :statement do
        rule %r/(#{id})(\s*)(:)/ do
          groups Name::Label, Text, Punctuation
        end

        rule %r/[{}]/, Punctuation

        mixin :expr_start
      end

      # object literals
      state :object do
        mixin :comments_and_whitespace
        rule %r/[}]/ do
          token Punctuation
          goto :statement
        end

        rule %r/(#{id})(\s*)(:)/ do
          groups Name::Attribute, Text, Punctuation
          push :expr_start
        end

        rule %r/:/, Punctuation
        mixin :root
      end

      # ternary expressions, where <id>: is not a label!
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
