module Articles
  module Feeds
    module FindFeaturedStory
      def self.call(stories)
        featured_story =
          if stories.is_a?(ActiveRecord::Relation)
            stories.where.not(main_image: nil).first
          else
            stories.detect { |story| story.main_image.present? }
          end

        featured_story || Article.new
      end
    end
  end
end
