# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'c.rb'

    class Slice < C
      tag 'slice'
      filenames '*.ice'
      mimetypes 'text/slice'

      title "Slice"
      desc "Specification Language for Ice (doc.zeroc.com)"

      def self.keywords
        @keywords ||= Set.new %w(
          extends implements enum interface struct class module dictionary
          const optional out throws exception local idempotent sequence

          Object LocalObject Value
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          bool string byte long float double int void short
        )
      end
    end
  end
end
