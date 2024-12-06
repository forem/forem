# frozen_string_literal: true

require "zlib"
require "sax-machine"
require "loofah"
require "logger"
require "json"

require "feedjira/core_ext"
require "feedjira/configuration"
require "feedjira/feed_entry_utilities"
require "feedjira/feed_utilities"
require "feedjira/feed"
require "feedjira/rss_entry_utilities"
require "feedjira/atom_entry_utilities"
require "feedjira/parser"
require "feedjira/parser/globally_unique_identifier"
require "feedjira/parser/rss_entry"
require "feedjira/parser/rss_image"
require "feedjira/parser/rss"
require "feedjira/parser/atom_entry"
require "feedjira/parser/atom"
require "feedjira/preprocessor"
require "feedjira/version"

require "feedjira/parser/rss_feed_burner_entry"
require "feedjira/parser/rss_feed_burner"
require "feedjira/parser/podlove_chapter"
require "feedjira/parser/itunes_rss_owner"
require "feedjira/parser/itunes_rss_category"
require "feedjira/parser/itunes_rss_item"
require "feedjira/parser/itunes_rss"
require "feedjira/parser/atom_feed_burner_entry"
require "feedjira/parser/atom_feed_burner"
require "feedjira/parser/atom_google_alerts_entry"
require "feedjira/parser/atom_google_alerts"
require "feedjira/parser/google_docs_atom_entry"
require "feedjira/parser/google_docs_atom"
require "feedjira/parser/atom_youtube_entry"
require "feedjira/parser/atom_youtube"
require "feedjira/parser/json_feed"
require "feedjira/parser/json_feed_item"

# Feedjira
module Feedjira
  NoParserAvailable = Class.new(StandardError)

  extend Configuration

  # Parse XML with first compatible parser
  #
  # @example
  #   xml = HTTParty.get("http://example.com").body
  #   Feedjira.parse(xml)
  def parse(xml, parser: nil, &block)
    parser ||= parser_for_xml(xml)

    if parser.nil?
      raise NoParserAvailable, "No valid parser for XML."
    end

    parser.parse(xml, &block)
  end
  module_function :parse

  # Find compatible parser for given XML
  #
  # @example
  #   xml = HTTParty.get("http://example.com").body
  #   parser = Feedjira.parser_for_xml(xml)
  #   parser.parse(xml)
  def parser_for_xml(xml)
    start_of_doc = xml.slice(0, 2000)
    Feedjira.parsers.detect { |klass| klass.able_to_parse?(start_of_doc) }
  end
  module_function :parser_for_xml
end
