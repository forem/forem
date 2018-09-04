class FollowedArticlesController < ApplicationController
  # No authorization required for entirely public controller

  caches_action :index,
    cache_path: Proc.new { "followed_articles_#{current_user.id}__#{current_user.updated_at}__#{user_signed_in?}" },
    expires_in: 35.minutes

  def index
    @articles = if current_user
                  Rails.cache.fetch(
                    "user-#{current_user.id}__#{current_user.updated_at}/followed_articles",
                    expires_in: 30.minutes,
                  ) do
                    current_user.followed_articles.
                      includes(:user).where("published_at > ?", 5.days.ago).
                      order("hotness_score DESC").
                      limit(25).map do |a|
                        unless inappropriate_hiring_instance(a)
                          article_json(a)
                        end
                      end.compact
                  end
                else
                  @articles = []
                end
    classic_article = Suggester::Articles::Classic.new(current_user).get
    response.headers["Cache-Control"] = "public, max-age=150"
    render json: {
      articles: @articles,
      classic_article: (article_json(classic_article) if classic_article),
    }.to_json
  end

  def inappropriate_hiring_instance(article)
    (article.decorate.cached_tag_list_array.include?("hiring") && !article.approved) ||
      (article.decorate.cached_tag_list_array.include?("hiring") && current_user.cached_followed_tag_names.exclude?("hiring"))
  end

  def article_json(article)
    cache_key = "article_json-#{article.id}-#{article.updated_at}" \
      "-#{article.comments_count}-#{article.reactions_count}"
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      {
        id: article.id,
        path: article.path,
        tag_list: article.decorate.cached_tag_list_array,
        title: article.title,
        published_at_int: article.published_at.to_i,
        published_at_month_day: article.published_at.
          strftime("%B #{article.published_at.day.ordinalize}"),
        is_classic: article.published_at < 7.days.ago,
        comments_count: article.comments_count,
        reactions_count: article.positive_reactions_count,
        language: article.language,
        user: {
          name: article.user.name,
          username: article.user.username,
          profile_image_90: ProfileImage.new(article.user).get(90),
        },
        flare_tag: FlareTag.new(article).tag_hash,
      }
    end
  end
end
