module Articles
  module Feeds
    # @note In the current implementation this is inheriting from WeightedQueryStrategy; going
    #       forward, we want to move away from the less flexible WeightedQueryStrategy.  However, as
    #       we roll this out, we want both to be utilized.  In part so we can have a quick fallback
    #       to a known working state (e.g. WeightedQueryStrategy).  Assuming we move forward with
    #       this implementation, we will break the inheritance, copy the relevant methods over, and
    #       remove the WeightedQueryStrategy.
    class VariantQuery < WeightedQueryStrategy
      # @param variant [Symbol, #to_sym] the name of the variant query we're building.
      # @param assembler [Articles::Feeds::VariantAssembler, #call] responsible for converting the
      #        given variant to a config suitable for building a VariantQuery.
      # @param kwargs [Hash] named parameters to pass along to the #initialize method.
      #
      # @return [Articles::Feeds::VariantQuery]
      #
      # @see #initialize
      def self.build_for(variant:, assembler: VariantAssembler, **kwargs)
        config = assembler.call(variant: variant)
        new(config: config, **kwargs)
      end

      # Let's make sure that folks initialize this with a variant configuration.
      private_class_method :new

      Config = Struct.new(
        :variant,
        :levers, # Array <Articles::Feeds::RelevancyLever::Configured>
        :order_by, # Articles::Feeds::OrderByLever
        :max_days_since_published,
        :default_user_experience_level,
        :negative_reaction_threshold,
        :positive_reaction_threshold,
        keyword_init: true,
      )

      # @param config [Articles::Feeds::VariantQuery::Config]
      # @param user [User,NilClass]
      # @param number_of_articles [Integer, #to_i]
      # @param page [Integer, #to_i]
      # @param tag [NilClass] not used
      #
      # rubocop:disable Lint/MissingSuper
      def initialize(config:, user: nil, number_of_articles: 50, page: 1, tag: nil)
        @user = user
        @number_of_articles = number_of_articles
        @page = page
        @tag = tag
        @config = config
        @oldest_published_at = Articles::Feeds.oldest_published_at_to_consider_for(
          user: @user,
          days_since_published: max_days_since_published,
        )

        configure!
      end
      # rubocop:enable Lint/MissingSuper

      delegate(
        :max_days_since_published,
        :negative_reaction_threshold,
        :positive_reaction_threshold,
        :default_user_experience_level,
        to: :config,
      )

      attr_reader :config

      private

      def final_order_logic(articles)
        articles.order(config.order_by.to_sql)
      end

      def configure!
        @relevance_score_components = []

        # By default we always need to group by the articles.id
        # column.  And as we add scoring methods to the query, we need
        # to add additional group_by clauses based on the chosen
        # scoring method.
        @group_by_fields = Set.new
        @group_by_fields << "articles.id"

        @joins = Set.new

        # Ensure that we honor a user's block requests.
        unless @user.nil?
          @joins << "LEFT OUTER JOIN user_blocks
            ON user_blocks.blocked_id = articles.user_id
              AND user_blocks.blocked_id IS NULL
              AND user_blocks.blocker_id = :user_id"
        end

        config.levers.each do |lever|
          # Don't attempt to use this factor if we don't have user.
          next if lever.user_required? && @user.nil?

          # This scoring method requires a group by clause.
          @group_by_fields << lever.group_by_fragment if lever.group_by_fragment.present?

          @joins += lever.joins_fragments if lever.joins_fragments.present?

          @relevance_score_components << build_score_element_from(
            clause: lever.select_fragment,
            cases: lever.cases,
            fallback: lever.fallback,
          )
        end
      end
    end
  end
end
