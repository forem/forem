# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    module ObjectiveCCommon
      def at_keywords
        @at_keywords ||= %w(
          selector private protected public encode synchronized try
          throw catch finally end property synthesize dynamic optional
          interface implementation import autoreleasepool
        )
      end

      def at_builtins
        @at_builtins ||= %w(true false YES NO)
      end

      def builtins
        @builtins ||= %w(YES NO nil)
      end

      def self.extended(base)
        base.prepend :statements do
          rule %r/@"/, base::Str, :string
          rule %r/@'(\\[0-7]{1,3}|\\x[a-fA-F0-9]{1,2}|\\.|[^\\'\n]')/,
            base::Str::Char
          rule %r/@(\d+[.]\d*|[.]\d+|\d+)e[+-]?\d+l?/i,
            base::Num::Float
          rule %r/@(\d+[.]\d*|[.]\d+|\d+f)f?/i, base::Num::Float
          rule %r/@0x\h+[lL]?/, base::Num::Hex
          rule %r/@0[0-7]+l?/i, base::Num::Oct
          rule %r/@\d+l?/, base::Num::Integer
          rule %r/\bin\b/, base::Keyword

          rule %r/@(?:interface|implementation)\b/, base::Keyword, :objc_classname
          rule %r/@(?:class|protocol)\b/, base::Keyword, :forward_classname

          rule %r/@([[:alnum:]]+)/ do |m|
            if base.at_keywords.include? m[1]
              token base::Keyword
            elsif base.at_builtins.include? m[1]
              token base::Name::Builtin
            else
              token base::Error
            end
          end

          rule %r/[?]/, base::Punctuation, :ternary
          rule %r/\[/,  base::Punctuation, :message
          rule %r/@\[/, base::Punctuation, :array_literal
          rule %r/@\{/, base::Punctuation, :dictionary_literal
        end

        id = /[a-z$_][a-z0-9$_]*/i

        base.state :ternary do
          rule %r/:/, base::Punctuation, :pop!
          mixin :statements
        end

        base.state :message_shared do
          rule %r/\]/, base::Punctuation, :pop!
          rule %r/\{/, base::Punctuation, :pop!
          rule %r/;/, base::Error

          mixin :statements
        end

        base.state :message do
          rule %r/(#{id})(\s*)(:)/ do
            groups(base::Name::Function, base::Text, base::Punctuation)
            goto :message_with_args
          end

          rule %r/(#{id})(\s*)(\])/ do
            groups(base::Name::Function, base::Text, base::Punctuation)
            pop!
          end

          mixin :message_shared
        end

        base.state :message_with_args do
          rule %r/\{/, base::Punctuation, :function
          rule %r/(#{id})(\s*)(:)/ do
            groups(base::Name::Function, base::Text, base::Punctuation)
            pop!
          end

          mixin :message_shared
        end

        base.state :array_literal do
          rule %r/]/, base::Punctuation, :pop!
          rule %r/,/, base::Punctuation
          mixin :statements
        end

        base.state :dictionary_literal do
          rule %r/}/, base::Punctuation, :pop!
          rule %r/,/, base::Punctuation
          mixin :statements
        end

        base.state :objc_classname do
          mixin :whitespace

          rule %r/(#{id})(\s*)(:)(\s*)(#{id})/ do
            groups(base::Name::Class, base::Text,
                   base::Punctuation, base::Text,
                   base::Name::Class)
            pop!
          end

          rule %r/(#{id})(\s*)([(])(\s*)(#{id})(\s*)([)])/ do
            groups(base::Name::Class, base::Text,
                   base::Punctuation, base::Text,
                   base::Name::Label, base::Text,
                   base::Punctuation)
            pop!
          end

          rule id, base::Name::Class, :pop!
        end

        base.state :forward_classname do
          mixin :whitespace

          rule %r/(#{id})(\s*)(,)(\s*)/ do
            groups(base::Name::Class, base::Text, base::Punctuation, base::Text)
            push
          end

          rule %r/(#{id})(\s*)(;?)/ do
            groups(base::Name::Class, base::Text, base::Punctuation)
            pop!
          end
        end

        base.prepend :root do
          rule %r(
            ([-+])(\s*)
            ([(].*?[)])?(\s*)
            (?=#{id}:?)
          )ix do |m|
            token base::Keyword, m[1]
            token base::Text, m[2]
            recurse(m[3]) if m[3]
            token base::Text, m[4]
            push :method_definition
          end
        end

        base.state :method_definition do
          rule %r/,/, base::Punctuation
          rule %r/[.][.][.]/, base::Punctuation
          rule %r/([(].*?[)])(#{id})/ do |m|
            recurse m[1]; token base::Name::Variable, m[2]
          end

          rule %r/(#{id})(\s*)(:)/m do
            groups(base::Name::Function, base::Text, base::Punctuation)
          end

          rule %r/;/, base::Punctuation, :pop!

          rule %r/{/ do
            token base::Punctuation
            goto :function
          end

          mixin :inline_whitespace
          rule %r(//.*?\n), base::Comment::Single
          rule %r/\s+/m, base::Text

          rule(//) { pop! }
        end
      end
    end
  end
end
