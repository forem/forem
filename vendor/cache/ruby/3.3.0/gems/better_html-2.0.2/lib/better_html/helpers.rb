# frozen_string_literal: true

module BetterHtml
  module Helpers
    def html_attributes(args)
      BetterHtml::HtmlAttributes.new(args)
    end
  end
end
