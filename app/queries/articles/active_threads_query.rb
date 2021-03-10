module Articles
  class ActiveThreadsQuery
    DEFAULT_OPTIONS = {
      tags: ["discuss"],
      time_ago: nil,
      count: 10
    }.with_indifferent_access.freeze

    MINIMUM_SCORE = -4

    def self.call(relation: Article.published, options: {})
      options = DEFAULT_OPTIONS.merge(options)
      tags, time_ago, count = options.values_at(:tags, :time_ago, :count)

      relation.limit(count)
      relation = if time_ago == "latest"
                   relation.order(published_at: :desc).where(score: MINIMUM_SCORE..).presence ||
                     relation.order(published_at: :desc)
                 elsif time_ago
                   relation.order(comments_count: :desc)
                     .where(published_at: time_ago.., score: MINIMUM_SCORE..).presence ||
                     relation.order(comments_count: :desc)
                 else
                   relation.order(last_comment_at: :desc)
                     .where(published_at: (tags.present? ? 5 : 2).days.ago.., score: MINIMUM_SCORE..).presence ||
                     relation.order(last_comment_at: :desc)
                 end
      relation = tags.size == 1 ? relation.cached_tagged_with(tags.first) : relation.tagged_with(tags)
      relation.pluck(:path, :title, :comments_count, :created_at)
    end
  end
end
