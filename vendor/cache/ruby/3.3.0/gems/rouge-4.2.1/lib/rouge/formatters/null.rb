# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Formatters
    # A formatter which renders nothing.
    class Null < Formatter
      tag 'null'

      def initialize(*)
      end

      def stream(tokens, &b)
        tokens.each do |tok, val|
          yield "#{tok.qualname} #{val.inspect}\n"
        end
      end
    end
  end
end
