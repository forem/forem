module Follows
  class UpdatePointsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(follow_id)
      @follow = Follow
        .includes(:follower, :followable)
        .find_by(id: follow_id)
      return unless @follow&.followable&.following?(follow.follower)



      @follow.implicit_points = calculate_implicit_points
      @follow.points = implicit_points + explicit_points
      @follow.save
    end

    def calculate_implicit_points
      recent_article_ids = @follow.user.reactions.public_category.where(reactable_type: "Article").last(80).pluck(:reactable_id)
      articles_count = Article.where(id: recent_article_ids)
    end
  end
end
