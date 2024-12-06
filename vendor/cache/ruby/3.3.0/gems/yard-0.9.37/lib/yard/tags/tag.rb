# frozen_string_literal: true
module YARD
  module Tags
    # Represents a metadata tag value (+@tag+). Tags can have any combination of
    # {#types}, {#name} and {#text}, or none of the above.
    #
    # @example Programmatic tag creation
    #   # The following docstring syntax:
    #   #   @param [String, nil] arg an argument
    #   #
    #   # is equivalent to:
    #   Tag.new(:param, 'an argument', ['String', 'nil'], 'arg')
    class Tag
      # @return [String] the name of the tag
      attr_accessor :tag_name

      # @return [String] the tag text associated with the tag
      # @return [nil] if no tag text is supplied
      attr_accessor :text

      # @return [Array<String>] a list of types associated with the tag
      # @return [nil] if no types are associated with the tag
      attr_accessor :types

      # @return [String] a name associated with the tag
      # @return [nil] if no tag name is supplied
      attr_accessor :name

      # @return [CodeObjects::Base] the associated object
      attr_accessor :object

      # Creates a new tag object with a tag name and text. Optionally, formally declared types
      # and a key name can be specified.
      #
      # Types are mainly for meta tags that rely on type information, such as +param+, +return+, etc.
      #
      # Key names are for tags that declare meta data for a specific key or name, such as +param+,
      # +raise+, etc.
      #
      # @param [#to_s] tag_name        the tag name to create the tag for
      # @param [String] text           the descriptive text for this tag
      # @param [Array<String>] types   optional type list of formally declared types
      #                                for the tag
      # @param [String] name           optional key name which the tag refers to
      def initialize(tag_name, text, types = nil, name = nil)
        @tag_name = tag_name.to_s
        @text = text
        @name = name
        @types = (types ? [types].flatten.compact : nil)
      end

      # Convenience method to access the first type specified. This should mainly
      # be used for tags that only specify one type.
      #
      # @return [String] the first of the list of specified types
      # @see #types
      def type
        types.first
      end

      # Provides a plain English summary of the type specification, or nil
      # if no types are provided or parsable.
      #
      # @return [String] a plain English description of the associated types
      # @return [nil] if no types are provided or not parsable
      def explain_types
        return nil if !types || types.empty?
        TypesExplainer.explain(*types)
      end
    end
  end
end
