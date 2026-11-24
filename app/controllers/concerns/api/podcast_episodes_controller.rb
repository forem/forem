module Api
  module PodcastEpisodesController
    extend ActiveSupport::Concern

    PODCAST_COLUMNS = %i[id title slug image].freeze
    private_constant :PODCAST_COLUMNS

    def index
      page = params[:page]
      per_page = (params[:per_page] || 30).to_i
      per_page_max = (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
      num = [per_page, per_page_max].min

      if params[:username]
        podcast = Podcast.available.find_by!(slug: params[:username])
        base_scope = podcast.podcast_episodes.reachable
      else
        podcast = nil
        base_scope = PodcastEpisode.reachable
      end

      paginated_scope = base_scope.order(published_at: :desc).page(page).per(num)
      if render_podcast_episodes_natively(paginated_scope, podcast)
        return
      end

      relation = podcast ? paginated_scope : paginated_scope.includes(:podcast)
      @podcast_episodes = relation.select(:id, :slug, :title, :podcast_id)
      set_surrogate_key_header PodcastEpisode.table_key, @podcast_episodes.map(&:record_key)
    end

    private

    def native_podcast_episodes_serializable?
      ForemNative.available? &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?)
    end

    def render_podcast_episodes_natively(scope, single_podcast)
      return false unless native_podcast_episodes_serializable?

      rows = scope.pluck(:id, :slug, :title, :podcast_id)
      if rows.empty?
        set_surrogate_key_header PodcastEpisode.table_key, []
        render json: "[]"
        return true
      end

      podcasts_by_id = if single_podcast
                         { single_podcast.id => single_podcast }
                       else
                         podcast_ids = rows.pluck(3).uniq
                         Podcast.where(id: podcast_ids).select(*PODCAST_COLUMNS).index_by(&:id)
                       end

      episodes_flat = []
      rows.each do |episode_id, slug, title, podcast_id|
        pod = podcasts_by_id[podcast_id]
        return false unless pod

        episodes_flat.push(
          episode_id,
          slug,
          title,
          nil,
          pod.title,
          pod.slug,
          pod.image_url,
        )
      end

      json_body = ForemNative.serialize_api_podcast_episodes_json(
        episodes_flat,
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
      return false unless json_body

      prefix = "#{PodcastEpisode.table_key}/"
      set_surrogate_key_header(PodcastEpisode.table_key, rows.map { |row| "#{prefix}#{row[0]}" })
      render json: json_body
      true
    end
  end
end
