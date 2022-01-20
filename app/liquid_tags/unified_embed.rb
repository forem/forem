require_relative "./unified_embed/tag"

# A namespacing module to help organize the concepts of embedding.
module UnifiedEmbed
  # A convenience method for registering tags as part of the
  # UnifiedEmbed ecosystem.
  #
  # @see UnifiedEmbed::Registry
  def self.register(...)
    UnifiedEmbed::Registry.register(...)
  end
end
