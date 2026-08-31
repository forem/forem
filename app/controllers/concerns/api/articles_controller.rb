module Api
  module ArticlesController
    extend ActiveSupport::Concern

    included do
      before_action :validate_page_limit, only: %i[index search]
    end

    INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id collection_id
      title description main_image published_at crossposted_at social_image
      cached_tag_list slug path canonical_url comments_count
      public_reactions_count created_at edited_at last_comment_at published
      updated_at video_thumbnail_url reading_time subforem_id language
      ai_disclosure_level
    ].freeze

    ADDITIONAL_SEARCH_ATTRIBUTES_FOR_SERIALIZATION = [
      *INDEX_ATTRIBUTES_FOR_SERIALIZATION, :body_markdown
    ].freeze
    private_constant :ADDITIONAL_SEARCH_ATTRIBUTES_FOR_SERIALIZATION

    SHOW_ATTRIBUTES_FOR_SERIALIZATION = [
      *INDEX_ATTRIBUTES_FOR_SERIALIZATION, :body_markdown, :processed_html
    ].freeze
    private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

    ME_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id
      title description main_image published published_at cached_tag_list
      slug path canonical_url comments_count public_reactions_count
      page_views_count crossposted_at body_markdown updated_at reading_time
      ai_disclosure_level
    ].freeze
    private_constant :ME_ATTRIBUTES_FOR_SERIALIZATION

    def index
      if invalid_tags_present?
        render json: { error: "Not Found", status: 404 }, status: :not_found
        return
      end

      @articles = ArticleApiIndexService.new(params).get
      @articles = @articles.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).decorate

      set_surrogate_key_header Article.table_key, @articles.map(&:record_key)
    end

    def show
      @article = Article.published.from_subforem
        .includes(user: :profile)
        .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find(params[:id])
        .decorate

      set_surrogate_key_header @article.record_key
    end

    def show_by_slug
      @article = Article.published.from_subforem
        .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find_by!(path: "/#{params[:username]}/#{params[:slug]}")
        .decorate

      set_surrogate_key_header @article.record_key
      render "show"
    end

    def create
      authorize(Article)

      return if render_missing_ai_disclosure

      @article = Articles::Creator.call(@user, article_params).decorate

      if @article.persisted?
        render "show", status: :created, location: @article.url
      else
        message = @article.errors_as_sentence
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end

    def update
      articles_relation = @user.super_admin? ? Article.includes(:user) : @user.articles
      article = articles_relation.find(params[:id])

      result = Articles::Updater.call(@user, article, article_params)

      @article = result.article

      if result.success
        assign_ai_disclosure_warning
        render "show", status: :ok
      else
        message = @article.errors_as_sentence
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end

    def me
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, per_page_max].min

      @articles = case params[:status]
                  when "published"
                    @user.articles.published.from_subforem
                  when "unpublished"
                    @user.articles.unpublished.from_subforem
                  when "all"
                    @user.articles.from_subforem
                  else
                    @user.articles.published.from_subforem
                  end

      @articles = @articles
        .includes(:organization)
        .select(ME_ATTRIBUTES_FOR_SERIALIZATION)
        .order(published_at: :desc, created_at: :desc)
        .page(params[:page])
        .per(num)
        .decorate
    end

    def unpublish
      @article = Article.find(params[:id])

      authorize @article, :revoke_publication?

      if Articles::Unpublish.call(@user, @article)
        payload = { action: "api_article_unpublish", article_id: @article.id }
        Audit::Logger.log(:admin_api, @user, payload)

        render status: :no_content
      else
        render json: { message: @article.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def search
      # I temporarily added a new search endpoint in the interest of getting the chatGPT plugin live without changing
      # the existing index endpoint. There are some experiments which we want to conduct which I think makes sense on
      # a new endpoint rather than an existing one. We may want to refactor the index one in the future.
      @articles = Articles::ApiSearchQuery.call(params)

      # This adds some inconsistency where we omit the body markdown when the response has more than 1 article because
      # ChatGPT cannot process the long body request.
      @articles = if @articles.count > 1
                    @articles.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).decorate
                  else
                    @articles.select(ADDITIONAL_SEARCH_ATTRIBUTES_FOR_SERIALIZATION).decorate
                  end
    end

    private

    def invalid_tags_present?
      tag_params = [params[:tag], params[:tags], params[:tags_exclude]].flatten.compact

      return false if tag_params.empty?

      all_tags = tag_params.flat_map { |t| t.to_s.split(",") }.map(&:strip).compact_blank

      all_tags.any? { |t| !t.match?(/\A[[:alnum:]\-]+\z/i) }
    end

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end

    # Agents that never read /llms.txt otherwise publish with no disclosure at all,
    # so creating over the API requires an explicit choice. Any of the four enum
    # values is accepted, including `not_disclosed` — the point is a deliberate
    # answer, not a particular one.
    def render_missing_ai_disclosure
      return false unless Settings::General.enable_ai_disclosure
      return false if params.dig("article", :ai_disclosure_level).present?
      return false if ai_disclosure_in_front_matter?

      render json: {
        error: "ai_disclosure_level is required when creating an article. " \
               "Set it to one of: #{Article.ai_disclosure_levels.keys.join(', ')}.",
        status: 422,
        ai_disclosure_level: {
          required: true,
          allowed_values: Article.ai_disclosure_levels.keys,
          policy_url: URL.url("llms.txt")
        }
      }, status: :unprocessable_entity
      true
    end

    # /llms.txt offers front matter as an equally valid way to disclose, so a
    # payload that discloses there must not be rejected. Mirrors the keys handled
    # by Article#set_ai_disclosure_from_front_matter.
    AI_DISCLOSURE_FRONT_MATTER_KEYS = %w[ai_disclosure_level ai_disclosure ai_generated ai_assisted].freeze

    def ai_disclosure_in_front_matter?
      body = params.dig("article", :body_markdown)
      return false if body.blank?

      front_matter = FrontMatterParser::Parser.new(:md).call(body).front_matter
      return false unless front_matter.is_a?(Hash)

      AI_DISCLOSURE_FRONT_MATTER_KEYS.any? { |key| front_matter[key].present? }
    rescue StandardError
      # Malformed front matter is the model's problem to report, not a reason to
      # claim the article was undisclosed.
      false
    end

    # Updates stay permissive: every article predating this feature is
    # `not_disclosed`, so requiring a value here would break existing clients
    # editing old posts. Warn instead.
    def assign_ai_disclosure_warning
      return unless Settings::General.enable_ai_disclosure
      return unless @article.not_disclosed?

      @warnings = [
        "This article has ai_disclosure_level=not_disclosed. Set it to one of: " \
        "#{Article.ai_disclosure_levels.keys.join(', ')}. See #{URL.url('llms.txt')}"
      ]
    end

    def article_params
      convert_labels_param
      allowed_params = [
        :title, :body_markdown, :published, :series,
        :main_image, :canonical_url, :description, { tags: [] },
        :published_at, :subforem_id, :language
      ]
      allowed_params << :ai_disclosure_level if Settings::General.enable_ai_disclosure
      allowed_params << :organization_id if params.dig("article", "organization_id") && allowed_to_change_org_id?
      # allow if a youtube.com, mux.com, or twitch.tv URL
      video_url = params.dig("article", "video_source_url")
      if video_url.present?
        youtube_pattern = /\Ahttps?:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)/
        mux_pattern = /\Ahttps?:\/\/player\.mux\.com\//
        twitch_pattern = /\Ahttps?:\/\/(www\.)?twitch\.tv\/videos\//
        allowed_params << :video_source_url if video_url.match?(youtube_pattern) || video_url.match?(mux_pattern) || video_url.match?(twitch_pattern)
      end
      if @user.super_admin?
        allowed_params << :clickbait_score
        allowed_params << :compellingness_score
        allowed_params << { labels: [] }
      end
      params.require(:article).permit(allowed_params)
    end

    def allowed_to_change_org_id?
      potential_user = @article&.user || @user
      if @article.nil? || OrganizationMembership.exists?(user: potential_user,
                                                         organization_id: params.dig("article", "organization_id"))
        OrganizationMembership.exists?(user: potential_user,
                                       organization_id: params.dig("article", "organization_id"))
      elsif potential_user == @user
        potential_user.org_admin?(params.dig("article", "organization_id")) ||
          @user.any_admin?
      end
    end

    def validate_article_param_is_hash
      return if params.to_unsafe_h[:article].is_a?(Hash)

      message = I18n.t("api.v0.articles_controller.must_be_json", type: params[:article].class.name)
      render json: { error: message, status: 422 }, status: :unprocessable_entity
    end

    def convert_labels_param
      labels = params.dig("article", "labels")
      if labels.present?
        labels = labels.is_a?(String) ? labels.gsub(" ", "").split(",") : labels
        params[:article][:labels] = labels
      end
    end

    def validate_page_limit
      return if params[:page].to_i <= 1000
      return if authenticate_with_api_key

      message = I18n.t("api.v0.articles_controller.page_limit_exceeded")
      render json: { error: message, status: 401 }, status: :unauthorized
    end
  end
end
