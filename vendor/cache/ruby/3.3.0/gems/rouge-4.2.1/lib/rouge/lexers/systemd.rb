# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class SystemD < RegexLexer
      tag 'systemd'
      aliases 'unit-file'
      filenames '*.service'
      mimetypes 'text/x-systemd-unit'
      desc 'A lexer for systemd unit files'

      state :root do
        rule %r/\s+/, Text
        rule %r/[;#].*/, Comment
        rule %r/\[.*?\]$/, Keyword
        rule %r/(.*?)(=)(.*)(\\\n)/ do
          groups Name::Tag, Punctuation, Text, Str::Escape
          push :continuation
        end
        rule %r/(.*?)(=)(.*)/ do
          groups Name::Tag, Punctuation, Text
        end
      end

      state :continuation do
        rule %r/(.*?)(\\\n)/ do
          groups Text, Str::Escape
        end
        rule %r/(.*)'?/, Text, :pop!
      end
    end
  end
end
