require 'forwardable'
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/errors'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/request'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/url'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/parser'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/parsers/base'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/parsers/images'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/parsers/links'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/parsers/head_links'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/parsers/meta_tags'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/parsers/texts'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/document'))
require File.expand_path(File.join(File.dirname(__FILE__), 'meta_inspector/version'))

module MetaInspector
  extend self

  # Sugar method to be able to scrape a document in a shorter way
  def new(url, options = {})
    Document.new(url, options)
  end
end
