# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Java < RegexLexer
      title "Java"
      desc "The Java programming language (java.com)"

      tag 'java'
      filenames '*.java'
      mimetypes 'text/x-java'

      keywords = %w(
        assert break case catch continue default do else finally for
        if goto instanceof new return switch this throw try while
      )

      declarations = %w(
        abstract const enum extends final implements native private protected
        public static strictfp super synchronized throws transient volatile
      )

      types = %w(boolean byte char double float int long short var void)

      id = /[[:alpha:]_][[:word:]]*/
      const_name = /[[:upper:]][[:upper:][:digit:]_]*\b/
      class_name = /[[:upper:]][[:alnum:]]*\b/

      state :root do
        rule %r/[^\S\n]+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/\*.*?\*/)m, Comment::Multiline
        # keywords: go before method names to avoid lexing "throw new XYZ"
        # as a method signature
        rule %r/(?:#{keywords.join('|')})\b/, Keyword

        rule %r(
          (\s*(?:[a-zA-Z_][a-zA-Z0-9_.\[\]<>]*\s+)+?) # return arguments
          ([a-zA-Z_][a-zA-Z0-9_]*)                  # method name
          (\s*)(\()                                 # signature start
        )mx do |m|
          # TODO: do this better, this shouldn't need a delegation
          delegate Java, m[1]
          token Name::Function, m[2]
          token Text, m[3]
          token Operator, m[4]
        end

        rule %r/@#{id}/, Name::Decorator
        rule %r/(?:#{declarations.join('|')})\b/, Keyword::Declaration
        rule %r/(?:#{types.join('|')})\b/, Keyword::Type
        rule %r/(?:true|false|null)\b/, Keyword::Constant
        rule %r/(?:class|interface)\b/, Keyword::Declaration, :class
        rule %r/(?:import|package)\b/, Keyword::Namespace, :import
        rule %r/"""\s*\n.*?(?<!\\)"""/m, Str::Heredoc
        rule %r/"(\\\\|\\"|[^"])*"/, Str
        rule %r/'(?:\\.|[^\\]|\\u[0-9a-f]{4})'/, Str::Char
        rule %r/(\.)(#{id})/ do
          groups Operator, Name::Attribute
        end

        rule %r/#{id}:/, Name::Label
        rule const_name, Name::Constant
        rule class_name, Name::Class
        rule %r/\$?#{id}/, Name
        rule %r/[~^*!%&\[\](){}<>\|+=:;,.\/?-]/, Operator

        digit = /[0-9]_+[0-9]|[0-9]/
        bin_digit = /[01]_+[01]|[01]/
        oct_digit = /[0-7]_+[0-7]|[0-7]/
        hex_digit = /[0-9a-f]_+[0-9a-f]|[0-9a-f]/i
        rule %r/#{digit}+\.#{digit}+([eE]#{digit}+)?[fd]?/, Num::Float
        rule %r/0b#{bin_digit}+/i, Num::Bin
        rule %r/0x#{hex_digit}+/i, Num::Hex
        rule %r/0#{oct_digit}+/, Num::Oct
        rule %r/#{digit}+L?/, Num::Integer
        rule %r/\n/, Text
      end

      state :class do
        rule %r/\s+/m, Text
        rule id, Name::Class, :pop!
      end

      state :import do
        rule %r/\s+/m, Text
        rule %r/[a-z0-9_.]+\*?/i, Name::Namespace, :pop!
      end
    end
  end
end
