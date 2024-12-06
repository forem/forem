# frozen_string_literal: true

require 'front_matter_parser/loader/yaml'

module FrontMatterParser
  # This module includes front matter loaders (from a string -usually extracted
  # with a {SyntaxParser}- to hash). They must respond to a `::call` method
  # which accepts the String as argument and respond with a Hash.
  module Loader
  end
end
