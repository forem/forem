module Follows
  class UpdatePointsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(reactable_id, user_id)
      article = Article.find(reactable_id)
      user = User.find(user_id)
      return unless article && user

      article.decorate.cached_tag_list_array.each do |tag_name|
        if user.cached_followed_tag_names.include?(tag_name)
          recalculate_tag_follow_points(tag_name, user)
        end
      end
    end

    def recalculate_tag_follow_points(tag_name, user)
      tag = Tag.find_by(name: tag_name)
      follow = Follow.follower_tag(user.id).where(followable_id: tag.id)

      follow.implicit_points = calculate_implicit_points(tag, user)
      follow.points = implicit_points + follow.explicit_points
      follow.save
    end

    def calculate_implicit_points(tag, user)
      last_100_reactable_ids = user.reactions.where("points > 0").where(reactable_type: "Article")
        .pluck(:reactable_id).last(100)
      last_100_long_page_view_article_ids = user.page_views.where("time_tracked_in_seconds > 45")
        .pluck(:article_id).last(100)
      articles = Article.where(id: last_100_reactable_ids + last_100_long_page_view_article_ids)
      tags = articles.pluck(:cached_tag_list).map { |list| list.split(", ") }.flatten
      occurrences = tags.count(tag.name)
      Math.log(occurrences)
    end
  end
end
