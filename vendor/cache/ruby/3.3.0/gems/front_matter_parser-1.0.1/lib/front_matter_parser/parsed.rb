# frozen_string_literal: true

module FrontMatterParser
  # Result of parsing front matter and content from a string
  class Parsed
    # @!attribute [rw] front_matter
    # @see #initialize
    attr_reader :front_matter

    # @!attribute [rw] content
    # @see #initialize
    attr_reader :content

    # @param front_matter [Hash] parsed front_matter
    # @param content [String] parsed content
    def initialize(front_matter:, content:)
      @front_matter = front_matter
      @content = content
    end

    # Returns front matter value for given key
    #
    # @param key [String] key for desired value
    # @return [String, Array, # Hash] desired value
    def [](key)
      front_matter[key]
    end
  end
end
