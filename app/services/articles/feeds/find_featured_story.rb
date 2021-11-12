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
