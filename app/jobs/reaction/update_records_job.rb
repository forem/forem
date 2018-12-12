module Reaction
  class UpdateRecordsJob < ApplicationJob
    queue_as :default

    def perform(reactable, user)
      reactable_type = reactable.class.name

      if reactable_type == "Article"
        cache_buster = CacheBuster.new
        reactable.async_score_calc
        reactable.index!
        cache_buster.bust "/reactions?article_id=#{reactable.id}"
        cache_buster.bust user.path
      elsif reactable_type == "Comment"
        cache_buster = CacheBuster.new
        reactable.save
        cache_buster.bust "/reactions?commentable_id=#{reactable.commentable_id}&commentable_type=#{reactable.commentable_type}"
        cache_buster.bust user.path
      end

      user.touch

      if rand(6) == 1 || reactable.positive_reactions_count.negative?
        reactable.update_column(:positive_reactions_count, reactable.reactions.where("points > ?", 0).size)
      end
    end
  end
end
