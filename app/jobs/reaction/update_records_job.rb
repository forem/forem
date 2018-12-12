module Reaction
  class UpdateRecordsJob < ApplicationJob
    queue_as :default

    attr_reader :reactable, :user

    def perform(reactable, user)
      @reactable = reactable
      @user = user

      reactable_type = reactable.class.name

      if reactable_type == "Article"
        update_article
      elsif reactable_type == "Comment"
        update_comment
      end
      user.touch
      occasionally_sync_reaction_counts
    end

    private

    def update_article
      cache_buster = CacheBuster.new
      reactable.async_score_calc
      reactable.index!
      cache_buster.bust "/reactions?article_id=#{reactable.id}"
      cache_buster.bust user.path
    end

    def update_comment
      cache_buster = CacheBuster.new
      reactable.save
      cache_buster.bust "/reactions?commentable_id=#{reactable.commentable_id}&commentable_type=#{reactable.commentable_type}"
      cache_buster.bust user.path
    end

    def occasionally_sync_reaction_counts
      # Fixes any out-of-sync positive_reactions_count
      if rand(6) == 1 || reactable.positive_reactions_count.negative?
        reactable.update_column(:positive_reactions_count, reactable.reactions.where("points > ?", 0).size)
      end
    end
  end
end
