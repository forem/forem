# frozen_string_literal: true

require 'nokogiri'

require 'xpath/dsl'
require 'xpath/expression'
require 'xpath/literal'
require 'xpath/union'
require 'xpath/renderer'

module XPath
  extend XPath::DSL
  include XPath::DSL

  def self.generate
    yield(self)
  end
end
