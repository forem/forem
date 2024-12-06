# frozen_string_literal: true

require 'front_matter_parser/syntax_parser/factorizable'
require 'front_matter_parser/syntax_parser/multi_line_comment'
require 'front_matter_parser/syntax_parser/indentation_comment'
require 'front_matter_parser/syntax_parser/single_line_comment'

module FrontMatterParser
  # This module includes parsers for different syntaxes.  They respond to
  # a method `#call`, which takes a string as argument and responds with
  # a hash interface with `:front_matter` and `:content` keys, or `nil` if no
  # front matter is found.
  #
  # :reek:TooManyConstants
  module SyntaxParser
    Coffee = SingleLineComment['#']
    Sass = SingleLineComment['//']
    Scss = SingleLineComment['//']

    Html = MultiLineComment['<!--', '-->']
    Erb = MultiLineComment['<%#', '%>']
    Liquid = MultiLineComment['{% comment %}', '{% endcomment %}']
    Md = MultiLineComment['', '']

    Slim = IndentationComment['/']
    Haml = IndentationComment['-#']
  end
end
