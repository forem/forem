# [PROJECT_ROOT]/app/workers/articles/update_page_views_worker.rb

module Articles
  class UpdatePageViewsWorker
    include Sidekiq::Job

    GOOGLE_REFERRER = "https://www.google.com/".freeze

    # Authoritative bot filter. The client gate in baseTracking.js can be
    # bypassed by any non-browser client that POSTs to /page_views directly,
    # so self-identified crawlers must also be dropped here before a row is
    # written. Kept in parity with the client-side list.
    BOT_USER_AGENT_REGEX = /
  \b(bot|gptbot|crawl|spider)\b|
  google|baidu|bing|msn|duckduckbot|teoma|slurp|
  yandex|chatgpt|anthropic|cohere-ai|facebookexternalhit
/ix

    sidekiq_options queue: :medium_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    retry: false

    def perform(create_params)
      create_params = sanitize_params(create_params.with_indifferent_access)
      return if bot_user_agent?(create_params[:user_agent])
      return unless valid_target?(create_params)

      if create_params[:article_id].present?
        article = find_published_article(create_params[:article_id])
        return unless article
        return if create_params[:user_id] && article.user_id == create_params[:user_id]
      end

      return unless create_page_view(create_params)
      return unless article

      update_article_views(article, create_params[:referrer])
    end

    private

    def sanitize_params(create_params)
      has_viewable_id = create_params[:viewable_id].present?
      has_viewable_type = create_params[:viewable_type].present?
      return create_params if has_viewable_id == has_viewable_type

      create_params.except(:viewable_id, :viewable_type)
    end

    def valid_target?(create_params)
      create_params[:article_id].present? ||
        (create_params[:viewable_id].present? && create_params[:viewable_type].present?)
    end

    def find_published_article(article_id)
      article = Article.select(:id, :published, :published_at, :user_id, :page_views_count)
        .find_by(id: article_id)
      article if article&.published?
    end

    def create_page_view(create_params)
      PageView.create!(create_params)
      true
    rescue ActiveRecord::RecordNotUnique
      # This is the most likely error. It happens when this job runs twice
      # due to a race condition. It's safe to ignore it, because the page
      # view has already been created. We can simply stop the worker.
      false
    rescue ActiveRecord::RecordInvalid => e
      # This indicates a data problem. We should log it to understand why
      # the params are bad, and then stop the worker.
      Rails.logger.error(
        "Articles::UpdatePageViewsWorker validation failed: #{e.message} for params: #{create_params}",
      )
      false
    end

    def update_article_views(article, referrer)
      updated_count = article.page_views.sum(:counts_for_number_of_views)
      if updated_count > article.page_views_count
        article.update_column(:page_views_count, updated_count)
      end

      return unless referrer == GOOGLE_REFERRER

      Articles::UpdateOrganicPageViewsWorker.perform_at(
        25.minutes.from_now,
        article.id,
      )
    end

    def bot_user_agent?(user_agent)
      user_agent.present? && BOT_USER_AGENT_REGEX.match?(user_agent)
    end
  end
end
