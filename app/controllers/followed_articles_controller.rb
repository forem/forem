class FollowedArticlesController < ApplicationController
  skip_before_action :ensure_signup_complete

  caches_action :index,
    :cache_path => Proc.new { "followed_articles_#{current_user.id}__#{current_user.updated_at}__#{user_signed_in?.to_s}" },
    :expires_in => 35.minutes

  def index
    if current_user
      @articles = Rails.cache.fetch("user-#{current_user.id}__#{current_user.updated_at}/followed_articles", expires_in: 30.minutes) do
        current_user.
          followed_articles.
          includes(:user).
          where("published_at > ?", 5.days.ago).
          order("hotness_score DESC").
          limit(25).
          map do |a|
            unless inappropriate_hiring_instance(a)
              article_json(a)
            end
          end.compact
      end
    else
      @articles = []
    end
    classic_article = ClassicArticle.new(current_user).get
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

  def article_json(a)
    Rails.cache.fetch("article_json-#{a.id}-#{a.updated_at}-#{a.comments_count}-#{a.reactions_count}", expires_in: 30.minutes) do
      {
        id: a.id,
        path: a.path,
        tag_list: a.decorate.cached_tag_list_array,
        title: a.title,
        published_at_int: a.published_at.to_i,
        published_at_month_day: a.published_at.strftime("%B #{a.published_at.day.ordinalize}"),
        is_classic: a.published_at < 7.days.ago,
        comments_count: a.comments_count,
        reactions_count: a.positive_reactions_count,
        language: a.language,
        user: {
          name: a.user.name,
          username: a.user.username,
          profile_image_90: ProfileImage.new(a.user).get(90),
        },
        flare_tag: FlareTag.new(a).tag_hash,
      }
    end
  end
end
