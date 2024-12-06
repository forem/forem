# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Properties < RegexLexer
      title ".properties"
      desc '.properties config files for Java'
      tag 'properties'

      filenames '*.properties'
      mimetypes 'text/x-java-properties'

      identifier = /[\w.-]+/

      state :basic do
        rule %r/[!#].*?\n/, Comment
        rule %r/\s+/, Text
        rule %r/\\\n/, Str::Escape
      end

      state :root do
        mixin :basic

        rule %r/(#{identifier})(\s*)([=:])/ do
          groups Name::Property, Text, Punctuation
          push :value
        end
      end

      state :value do
        rule %r/\n/, Text, :pop!
        mixin :basic
        rule %r/"/, Str, :dq
        rule %r/'.*?'/, Str
        mixin :esc_str
        rule %r/[^\\\n]+/, Str
      end

      state :dq do
        rule %r/"/, Str, :pop!
        mixin :esc_str
        rule %r/[^\\"]+/m, Str
      end

      state :esc_str do
        rule %r/\\u[0-9]{4}/, Str::Escape
        rule %r/\\./m, Str::Escape
      end
    end
  end
end
