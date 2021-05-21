class SearchController < ApplicationController
  before_action :authenticate_user!, only: %i[tags chat_channels reactions usernames]
  before_action :format_integer_params
  before_action :sanitize_params, only: %i[listings reactions feed_content]

  CHAT_CHANNEL_PARAMS = %i[
    channel_status
    channel_type
    page
    per_page
    status
    user_id
  ].freeze

  LISTINGS_PARAMS = [
    :category,
    :listing_search,
    :page,
    :per_page,
    :tag_boolean_mode,
    {
      tags: []
    },
  ].freeze

  REACTION_PARAMS = [
    :page,
    :per_page,
    :category,
    :search_fields,
    :tag_boolean_mode,
    {
      tag_names: [],
      status: []
    },
  ].freeze

  USER_PARAMS = %i[
    search_fields
    page
    per_page
  ].freeze

  FEED_PARAMS = [
    :approved,
    :class_name,
    :id,
    :organization_id,
    :page,
    :per_page,
    :search_fields,
    :sort_by,
    :sort_direction,
    :tag,
    :user_id,
    {
      tag_names: [],
      published_at: [:gte]
    },
  ].freeze

  def tags
    result = Search::Tag.search_documents(params[:name])

    render json: { result: result }
  end

  def chat_channels
    user_ids =
      if chat_channel_params[:user_id].present?
        [current_user.id, SiteConfig.mascot_user_id, chat_channel_params[:user_id]].reject(&:blank?)
      else
        [current_user.id]
      end

    result = Search::ChatChannelMembership.search_documents(
      user_ids: user_ids,
      page: chat_channel_params[:page],
      per_page: chat_channel_params[:per_page],
    )

    render json: { result: result }
  end

  def listings
    result = Search::Listing.search_documents(
      category: listing_params[:category],
      page: listing_params[:page],
      per_page: listing_params[:per_page],
      term: listing_params[:listing_search],
    )

    render json: { result: result }
  end

  def usernames
    result = Search::Username.search_documents(params[:username])

    render json: { result: result }
  end

  def feed_content
    class_name = feed_params[:class_name].to_s.inquiry

    is_homepage_search = (
      class_name.Article? &&
      feed_params[:search_fields].blank? &&
      feed_params[:sort_by].present?
    )

    result =
      if class_name.blank?
        search_postgres_article
      elsif is_homepage_search
        # NOTE: published_at is sent from the frontend in the following ES-friendly format:
        # => {"published_at"=>{"gte"=>"2021-04-06T14:53:23Z"}}
        published_at_gte = feed_params.dig(:published_at, :gte)
        published_at_gte = Time.zone.parse(published_at_gte) if published_at_gte
        published_at = published_at_gte ? published_at_gte.. : nil

        # Despite the name "Homepage", this is used by the following index pages:
        # => homepage (default, top week/month/year/infinity, latest)
        # => profile page
        # => organization page
        # => tag index page
        Homepage::FetchArticles.call(
          approved: feed_params[:approved],
          published_at: published_at,
          user_id: feed_params[:user_id],
          organization_id: feed_params[:organization_id],
          tags: feed_params[:tag_names],
          sort_by: params[:sort_by],
          sort_direction: params[:sort_direction],
          page: params[:page],
          per_page: params[:per_page],
        )
      elsif class_name.Comment?
        Search::Comment.search_documents(
          page: feed_params[:page],
          per_page: feed_params[:per_page],
          sort_by: feed_params[:sort_by],
          sort_direction: feed_params[:sort_direction],
          term: feed_params[:search_fields],
        )
      elsif class_name.PodcastEpisode?
        Search::PodcastEpisode.search_documents(
          page: feed_params[:page],
          per_page: feed_params[:per_page],
          sort_by: feed_params[:sort_by],
          sort_direction: feed_params[:sort_direction],
          term: feed_params[:search_fields],
        )
      elsif class_name.User?
        Search::User.search_documents(
          term: feed_params[:search_fields],
          page: feed_params[:page],
          per_page: feed_params[:per_page],
          sort_by: feed_params[:sort_by] == "published_at" ? :created_at : nil,
          sort_direction: feed_params[:sort_direction],
        )
      elsif class_name.Article?
        search_postgres_article
      end

    render json: { result: result }
  end

  def reactions
    # [@rhymes] we're recyling the existing params as we want to change the frontend as
    # little as possible, we might simplify in the future
    result = Search::ReadingList.search_documents(
      current_user,
      page: reaction_params[:page],
      per_page: reaction_params[:per_page],
      statuses: reaction_params[:status],
      tags: reaction_params[:tag_names],
      term: reaction_params[:search_fields],
    )

    render json: { result: result[:items], total: result[:total] }
  end

  private

  def search_postgres_article
    Search::Article.search_documents(
      term: feed_params[:search_fields],
      user_id: feed_params[:user_id],
      sort_by: feed_params[:sort_by],
      sort_direction: feed_params[:sort_direction],
      page: feed_params[:page],
      per_page: feed_params[:per_page],
    )
  end

  def chat_channel_params
    params.permit(CHAT_CHANNEL_PARAMS)
  end

  def listing_params
    params.permit(LISTINGS_PARAMS)
  end

  def user_params
    params.permit(USER_PARAMS)
  end

  def feed_params
    params.permit(FEED_PARAMS)
  end

  def reaction_params
    params.permit(REACTION_PARAMS)
  end

  def format_integer_params
    params[:page] = params[:page].to_i if params[:page].present?
    params[:per_page] = params[:per_page].to_i if params[:per_page].present?
  end

  # Some Elasticsearches/QueryBuilders treat values such as empty Strings and
  # nil differently. This is a helper method to remove any params that are
  # blank before passing it to Elasticsearch.
  def sanitize_params
    params.delete_if { |_k, v| v.blank? }
  end
end
