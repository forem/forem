# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Email < RegexLexer
      tag 'email'
      aliases 'eml', 'e-mail'
      filenames '*.eml'
      mimetypes 'message/rfc822'

      title "Email"
      desc "An email message"

      start do
        push :fields
      end

      state :fields do
        rule %r/[:]/, Operator, :field_body
        rule %r/[^\n\r:]+/, Name::Tag
        rule %r/[\n\r]/, Name::Tag
      end

      state :field_body do
        rule(/(\r?\n){2}/) { token Text; pop!(2) }
        rule %r/\r?\n(?![ \v\t\f])/, Text, :pop!
        rule %r/[^\n\r]+/, Name::Attribute
        rule %r/[\n\r]/, Name::Attribute
      end

      state :root do
        rule %r/\n/, Text
        rule %r/^>.*/, Comment
        rule %r/.+/, Text
      end
    end
  end
end
