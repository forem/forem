# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class HTTP < RegexLexer
      tag 'http'
      title "HTTP"
      desc 'http requests and responses'

      option :content, "the language for the content (default: auto-detect)"

      def self.http_methods
        @http_methods ||= %w(GET POST PUT DELETE HEAD OPTIONS TRACE PATCH QUERY)
      end

      def content_lexer
        @content_lexer ||= (lexer_option(:content) || guess_content_lexer)
      end

      def guess_content_lexer
        return Lexers::PlainText unless @content_type

        Lexer.guess_by_mimetype(@content_type)
      rescue Lexer::AmbiguousGuess
        Lexers::PlainText
      end

      start { @content_type = 'text/plain' }

      state :root do
        # request
        rule %r(
          (#{HTTP.http_methods.join('|')})([ ]+) # method
          ([^ ]+)([ ]+)                          # path
          (HTTPS?)(/)(\d(?:\.\d)?)(\r?\n|$)      # http version
        )ox do
          groups(
            Name::Function, Text,
            Name::Namespace, Text,
            Keyword, Operator, Num, Text
          )

          push :headers
        end

        # response
        rule %r(
          (HTTPS?)(/)(\d(?:\.\d)?)([ ]+) # http version
          (\d{3})([ ]+)?                 # status
          ([^\r\n]*)?(\r?\n|$)           # status message
        )x do
          groups(
            Keyword, Operator, Num, Text,
            Num, Text,
            Name::Exception, Text
          )
          push :headers
        end
      end

      state :headers do
        rule %r/([^\s:]+)( *)(:)( *)([^\r\n]+)(\r?\n|$)/ do |m|
          key = m[1]
          value = m[5]
          if key.strip.casecmp('content-type').zero?
            @content_type = value.split(';')[0].downcase
          end

          groups Name::Attribute, Text, Punctuation, Text, Str, Text
        end

        rule %r/([^\r\n]+)(\r?\n|$)/ do
          groups Str, Text
        end

        rule %r/\r?\n/, Text, :content
      end

      state :content do
        rule %r/.+/m do
          delegate(content_lexer)
        end
      end
    end
  end
end
