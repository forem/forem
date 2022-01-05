module Articles
  module Feeds
    module FindFeaturedStory
      # @param stories [ActiveRecord::Relation, #detect] pick a
      #        featured story from this enumerable
      # @param must_have_main_image [Boolean] if true, the featured
      #        story must have a main image
      # @return [Article]
      #
      # @note the must_have_main_image parameter name matches PR #15240
      #
      # @note One might assume that this would query on the
      #       `Articles.where(featured: true)` but in my sleuthing,
      #       the origin of this method's inner logic never included a
      #       consideration for `featured == true`.  Perhaps that
      #       should change?  This has been reported in
      #       https://github.com/forem/forem/issues/15613 and impacts
      #       Articles::Feeds::WeightedQueryStrategy.
      def self.call(stories, must_have_main_image: true)
        featured_story =
          if must_have_main_image
            if stories.is_a?(ActiveRecord::Relation)
              stories.where.not(main_image: nil).first
            else
              stories.detect { |story| story.main_image.present? }
            end
          else
            stories.first
          end

        featured_story || Article.new
      end
    end
  end
end
