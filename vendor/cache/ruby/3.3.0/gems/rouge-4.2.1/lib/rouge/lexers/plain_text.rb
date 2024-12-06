# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class PlainText < Lexer
      title "Plain Text"
      desc "A boring lexer that doesn't highlight anything"

      tag 'plaintext'
      aliases 'text'
      filenames '*.txt', 'Messages'
      mimetypes 'text/plain'

      attr_reader :token
      def initialize(*)
        super

        @token = token_option(:token) || Text
      end

      def stream_tokens(string, &b)
        yield self.token, string
      end
    end
  end
end
