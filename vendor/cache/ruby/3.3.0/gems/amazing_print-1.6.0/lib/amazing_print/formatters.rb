# frozen_string_literal: true

module AmazingPrint
  module Formatters
    require_relative 'formatters/object_formatter'
    require_relative 'formatters/struct_formatter'
    require_relative 'formatters/hash_formatter'
    require_relative 'formatters/array_formatter'
    require_relative 'formatters/simple_formatter'
    require_relative 'formatters/method_formatter'
    require_relative 'formatters/class_formatter'
    require_relative 'formatters/dir_formatter'
    require_relative 'formatters/file_formatter'
    require_relative 'colorize'
  end
end
