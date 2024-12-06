# frozen_string_literal: true

require_relative "base_erb"

module BetterHtml
  module Tokenizer
    class JavascriptErb < BaseErb
      private

      def add_text(text)
        pos = current_position
        add_token(:text, pos, pos + text.size) if text.present?
        append(text)
      end
    end
  end
end
