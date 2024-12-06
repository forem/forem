# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# Regular expressions based on https://github.com/SaswatPadhi/prismjs-bibtex
# and https://github.com/alecthomas/chroma/blob/master/lexers/b/bibtex.go

module Rouge
  module Lexers
    class BibTeX < RegexLexer
      title 'BibTeX'
      desc "BibTeX"
      tag 'bibtex'
      aliases 'bib'
      filenames '*.bib'

      valid_punctuation = Regexp.quote("@!$&.\\:;<>?[]^`|~*/+-")
      valid_name = /[a-z_#{valid_punctuation}][\w#{valid_punctuation}]*/io

      state :root do
        mixin :whitespace

        rule %r/@(#{valid_name})/o do |m|
          match = m[1].downcase

          if match == "comment"
            token Comment
          elsif match == "preamble"
            token Name::Class
            push :closing_brace
            push :value
            push :opening_brace
          elsif match == "string"
            token Name::Class
            push :closing_brace
            push :field
            push :opening_brace
          else
            token Name::Class
            push :closing_brace
            push :command_body
            push :opening_brace
          end
        end

        rule %r/.+/, Comment
      end

      state :opening_brace do
        mixin :whitespace
        rule %r/[{(]/, Punctuation, :pop!
      end

      state :closing_brace do
        mixin :whitespace
        rule %r/[})]/, Punctuation, :pop!
      end

      state :command_body do
        mixin :whitespace
        rule %r/[^\s\,\}]+/ do
          token Name::Label
          pop!
          push :fields
        end
      end

      state :fields do
        mixin :whitespace
        rule %r/,/, Punctuation, :field
        rule(//) { pop! }
      end

      state :field do
        mixin :whitespace
        rule valid_name do
          token Name::Attribute
          push :value
          push :equal_sign
        end
        rule(//) { pop! }
      end

      state :equal_sign do
        mixin :whitespace
        rule %r/=/, Punctuation, :pop!
      end

      state :value do
        mixin :whitespace
        rule valid_name, Name::Variable
        rule %r/"/, Literal::String, :quoted_string
        rule %r/\{/, Literal::String, :braced_string
        rule %r/\d+/, Literal::Number
        rule %r/#/, Punctuation
        rule(//) { pop! }
      end

      state :quoted_string do
        rule %r/\{/, Literal::String, :braced_string
        rule %r/"/, Literal::String, :pop!
        rule %r/[^\{\"]+/, Literal::String
      end

      state :braced_string do
        rule %r/\{/, Literal::String, :braced_string
        rule %r/\}/, Literal::String, :pop!
        rule %r/[^\{\}]+/, Literal::String
      end

      state :whitespace do
        rule %r/\s+/, Text
      end
    end
  end
end
