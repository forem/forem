module Articles
  module Feeds
    # This module is responsible for assembling a named variant into the data structure used to
    # build the feed query for a variant.
    #
    # @see .call
    module VariantAssembler
      # Assemble the named :variant based on the configuration of levers.
      #
      # @param variant [#to_sym,String,Symbol] the name of the variant we're assembling
      # @param levers [Articles::Feeds::LeverCatalogBuilder] the available levers for assembly
      # @param variants [Hash] the cache of previously assembled variants
      #
      # @return [Articles::Feeds::VariantQueryConfig]
      def self.call(variant:, levers: Articles::Feeds.lever_catalog, variants: variants_cache)
        variant = variant.to_sym
        variants[variant] ||= begin
          content = Rails.root.join("config/feed-variants/#{variant}.json").read
          config = JSON.parse(content)
          build_with(levers: levers, config: config, variant: variant)
        end
      end

      def self.variants_cache
        @variants_cache ||= {}
      end
      private_class_method :variants_cache

      def self.build_with(levers:, config:, variant:)
        relevancy_levers = config.fetch("levers").map do |key, settings|
          lever = levers.fetch_lever(key)
          ConfiguredLever.new(
            key: lever.key,
            user_required: lever.user_required,
            select_fragment: lever.select_fragment,
            joins_fragment: lever.joins_fragment,
            group_by_fragment: lever.group_by_fragment,
            cases: settings.fetch("cases"),
            fallback: settings.fetch("fallback"),
          )
        end

        VariantQueryConfig.new(
          variant: variant,
          levers: relevancy_levers,
          order_by: levers.fetch_order_by(config["order_by"]),
        )
      end
      private_class_method :build_with
    end

    VariantQueryConfig = Struct.new(
      :variant,
      :levers,
      :order_by,
      keyword_init: true,
    )

    ConfiguredLever = Struct.new(
      :key,
      :user_required,
      :select_fragment,
      :joins_fragment,
      :group_by_fragment,
      :cases,
      :fallback,
      keyword_init: true,
    ) do
      alias_method :user_required?, :user_required
    end
  end
end
