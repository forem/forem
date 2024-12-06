# frozen_string_literal: true

require_relative "../display_width" unless defined? Unicode::DisplayWidth

class String
  def display_width(ambiguous = 1, overwrite = {}, options = {})
    Unicode::DisplayWidth.of(self, ambiguous, overwrite, options)
  end
end
