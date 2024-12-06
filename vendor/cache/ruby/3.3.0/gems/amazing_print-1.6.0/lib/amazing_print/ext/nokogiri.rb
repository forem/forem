# frozen_string_literal: true

# Copyright (c) 2010-2016 Michael Dvorkin and contributors
#
# AmazingPrint is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AmazingPrint
  module Nokogiri
    def self.included(base)
      base.send :alias_method, :cast_without_nokogiri, :cast
      base.send :alias_method, :cast, :cast_with_nokogiri
    end

    # Add Nokogiri XML Node and NodeSet names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_nokogiri(object, type)
      cast = cast_without_nokogiri(object, type)
      if (defined?(::Nokogiri::XML::Node) && object.is_a?(::Nokogiri::XML::Node)) ||
         (defined?(::Nokogiri::XML::NodeSet) && object.is_a?(::Nokogiri::XML::NodeSet))
        cast = :nokogiri_xml_node
      end
      cast
    end

    #------------------------------------------------------------------------------
    def awesome_nokogiri_xml_node(object)
      return '[]' if object.is_a?(::Nokogiri::XML::NodeSet) && object.empty?

      xml = object.to_xml(indent: 2)
      #
      # Colorize tag, id/class name, and contents.
      #
      xml.gsub!(%r{(<)(/?[A-Za-z1-9]+)}) { |_tag| "#{Regexp.last_match(1)}#{colorize(Regexp.last_match(2), :keyword)}" }
      xml.gsub!(/(id|class)="[^"]+"/i) { |id| colorize(id, :class) }
      xml.gsub!(/>([^<]+)</) do |contents|
        contents = colorize(Regexp.last_match(1), :trueclass) if contents && !contents.empty?
        ">#{contents}<"
      end
      xml
    end
  end
end

AmazingPrint::Formatter.include AmazingPrint::Nokogiri
