module Api
  module VideosController
    extend ActiveSupport::Concern

    INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id video path title video_thumbnail_url user_id video_duration_in_seconds video_source_url
    ].freeze
    private_constant :INDEX_ATTRIBUTES_FOR_SERIALIZATION

    VIDEO_PLUCK_COLUMNS = [
      "articles.id",
      "articles.path",
      "articles.video_thumbnail_url",
      "articles.video",
      "articles.title",
      "articles.user_id",
      "articles.video_duration_in_seconds",
      "articles.video_source_url",
      "users.name",
    ].freeze
    private_constant :VIDEO_PLUCK_COLUMNS

    def index
      page = params[:page]
      per_page = (params[:per_page] || 24).to_i
      per_page_max = (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
      num = [per_page, per_page_max].min

      base_scope = Article.with_video.from_subforem
      base_scope = base_scope.cached_tagged_with(params[:tag]) if params[:tag].present?
      paginated_scope = base_scope.order(hotness_score: :desc).page(page).per(num)

      if render_videos_natively(paginated_scope)
        return
      end

      @video_articles = paginated_scope
        .includes([:user])
        .select(INDEX_ATTRIBUTES_FOR_SERIALIZATION)
      set_surrogate_key_header "videos", Article.table_key, @video_articles.map(&:record_key)
    end

    private

    def native_videos_serializable?
      ForemNative.available? &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?) &&
        !Images::Optimizer.imgproxy_enabled? &&
        !Images::Optimizer.cloudinary_enabled?
    end

    def render_videos_natively(scope)
      return false unless native_videos_serializable?

      rows = scope.joins(:user).pluck(*VIDEO_PLUCK_COLUMNS)
      cf_enabled = Images::Optimizer.cloudflare_enabled?
      config = [
        cf_enabled ? 1 : 0,
        cf_enabled ? ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"] : nil,
        Images::Optimizer::CLOUDFLARE_DIRECTORY,
        ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      ]
      json_body = ForemNative.serialize_api_videos_json(rows.flatten(1), config)
      return false unless json_body

      prefix = "#{Article.table_key}/"
      set_surrogate_key_header("videos", Article.table_key, rows.map { |row| "#{prefix}#{row[0]}" })
      render json: json_body
      true
    end
  end
end
