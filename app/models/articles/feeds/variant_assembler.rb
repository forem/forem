module Articles
  module Feeds
    # This module is responsible for assembling a named variant into the data structure used to
    # build the feed query for a variant.
    #
    # @see .call
    module VariantAssembler
      # The Rails root relative path to the directory of feed variants
      DIRECTORY = "config/feed-variants".freeze

      # The default extension for feed variants
      EXTENSION = "json".freeze

      # Assemble the named :variant based on the configuration of levers.
      #
      # @param variant [#to_sym,String,Symbol] the name of the variant we're assembling
      # @param catalog [Articles::Feeds::LeverCatalogBuilder] the available levers for assembly
      # @param variants [Hash] the cache of previously assembled variants; don't go rebuilding if we
      #        already have one.
      # @param dir [String] the relative directory that contains the variants.
      #
      # @raise [Errno::ENOENT] if named variant does not exist in DIRECTORY.  In other
      #        words, we have a mismatch in configuration.
      #
      # @return [Articles::Feeds::VariantQuery::Config]
      def self.call(variant:, catalog: Articles::Feeds.lever_catalog, variants: variants_cache, dir: DIRECTORY)
        variant = variant.to_sym
        variants[variant] ||= begin
          content = Rails.root.join(dir, "#{variant}.#{EXTENSION}").read
          config = JSON.parse(content)
          build_with(catalog: catalog, config: config, variant: variant)
        end
      end

      # @return [Hash<Symbol, VariantQuery::Config>]
      def self.variants_cache
        @variants_cache ||= {}
      end
      private_class_method :variants_cache

      # @param catalog [Articles::Feeds::LeverCatalogBuilder]
      # @param variant [Symbol]
      # @param config [Hash]
      #
      # @raise [KeyError] if we he have an invalidate configuration.
      #
      # @return [Articles::Feeds::VariantQuery::Config]
      def self.build_with(catalog:, config:, variant:)
        relevancy_levers = config.fetch("levers").map do |key, settings|
          lever = catalog.fetch_lever(key)
          lever.configure_with(**settings.symbolize_keys)
        end

        VariantQuery::Config.new(
          variant: variant,
          levers: relevancy_levers,
          order_by: catalog.fetch_order_by(config.fetch("order_by")),
          max_days_since_published: config.fetch("max_days_since_published"),
        )
      end
      private_class_method :build_with
    end
  end
end
