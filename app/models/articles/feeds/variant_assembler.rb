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

      # We have a "historical variant" that we renamed, hence we continue to maintain that name in
      # our data through the following map.
      VARIANT_NAME_MAP = {
        "20220422-jennie-variant": :"20220422-variant"
      }.freeze

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
      # @see .experiment_config_hash_for
      def self.call(variant:, catalog: Articles::Feeds.lever_catalog, variants: pre_assembled_variants, **kwargs)
        variant = variant.to_sym
        variants[variant] ||= begin
          config = user_config_hash_for(variant: variant, **kwargs)
          build_with(catalog: catalog, config: config, variant: variant)
        end
      end

      # @param variant [#to_sym,String,Symbol] the name of the variant we're assembling
      # @param dir [String] the relative directory that contains the variants.
      #
      # @return [Hash]
      #
      # @note Uses Rails.cache to minimize reads from file system.  The reason for the Rails.cache
      #       and not leveraging the .pre_assembled_variants is that this method
      #       (e.g. .experiment_config_hash_for) handles all possible variant configurations (in
      #       contrast to the active variants).
      #
      # @see app/views/field_test/experiments/_experiments.html.erb
      def self.user_config_hash_for(variant:, dir: DIRECTORY)
        Rails.cache.fetch("feed-variant-#{variant}-#{ForemInstance.latest_commit_id}", expires_in: 24.hours) do
          variant = VARIANT_NAME_MAP.fetch(variant.to_sym, variant)
          content = Rails.root.join(dir, "#{variant}.#{EXTENSION}").read
          JSON.parse(content)
        end
      end

      # A memoized (e.g. cached) module instance variable that provides the quickest access for
      # already assembled and active variant configurations.
      #
      # @return [Hash<Symbol, # VariantQuery::Config>]
      def self.pre_assembled_variants
        @pre_assembled_variants ||= {}
      end
      private_class_method :pre_assembled_variants

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
          description: config.fetch("description", ""),
          order_by: catalog.fetch_order_by(config.fetch("order_by")),
          max_days_since_published: config.fetch("max_days_since_published"),
          reseed_randomizer_on_each_request: config.fetch("reseed_randomizer_on_each_request"),
        )
      end
    end
  end
end
