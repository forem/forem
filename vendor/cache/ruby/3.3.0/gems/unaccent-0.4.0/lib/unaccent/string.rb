# frozen_string_literal: true

require 'unaccent'

module Unaccent
  # Extend the String class with unaccent method.
  module String
    def unaccent
      Unaccent.unaccent(self)
    end
  end
end

class String
  include Unaccent::String
end
