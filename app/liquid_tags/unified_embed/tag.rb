module UnifiedEmbed
  # This liquid tag is present to facilitate a unified user experience
  # for declaring that they want a URL to have "embedded" behavior.
  #
  # What do we mean by embedded behavior?  A more contextually rich
  # rendering of the URL, instead of a simple "A-tag".
  #
  # @see https://github.com/forem/forem/issues/15099 for details on the
  #      purpose of this class.
  class Tag < LiquidTagBase
    # You will not get a UnifiedEmbedTag instance, as we are instead
    # using this class as a lookup (e.g., Factory pattern?) for the
    # LiquidTagBase instance that is applicable for the given :link.
    #
    # @param tag_name [String] in the UI, this was liquid tag name
    #        (e.g., `{% tag_name link %}`)
    # @param link [String] the URL and additional options for that
    #        particular service.
    # @param parse_context [Liquid::ParseContext]
    #
    # @return [LiquidTagBase]
    def self.new(tag_name, link, parse_context)
      klass = UnifiedEmbed::Registry.find_liquid_tag_for(link: link)
      # If we don't know how to handle the embed, raise an error.
      # This avoids an A-tag that goes nowhere, and gives the user
      # a chance to correct the embed URL or choose how else to include
      # their content.
      raise StandardError, "Embed URL not valid" unless klass

      # Why the __send__?  Because a LiquidTagBase class "privatizes"
      # the `.new` method.  And we want to instantiate the specific
      # liquid tag for the given link.
      klass.__send__(:new, tag_name, link, parse_context)
    end
  end
end

Liquid::Template.register_tag("embed", UnifiedEmbed::Tag)
