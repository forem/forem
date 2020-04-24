class SearchController < ApplicationController
  before_action :authenticate_user!, only: %i[tags chat_channels reactions]
  before_action :format_integer_params
  before_action :sanitize_params, only: %i[classified_listings reactions feed_content]

  CLASSIFIED_LISTINGS_PARAMS = [
    :category,
    :classified_listing_search,
    :page,
    :per_page,
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
    :organization_id,
    :page,
    :per_page,
    :search_fields,
    :sort_by,
    :sort_direction,
    :user_id,
    {
      tag_names: [],
      published_at: [:gte]
    },
  ].freeze

  def tags
    tag_docs = Search::Tag.search_documents("name:#{params[:name]}* AND supported:true")

    render json: { result: tag_docs }
  rescue Search::Errors::Transport::BadRequest
    render json: { result: [] }
  end

  def chat_channels
    ccm_docs = Search::ChatChannelMembership.search_documents(
      params: chat_channel_params.merge(user_id: current_user.id).to_h,
    )

    render json: { result: ccm_docs }
  end

  def classified_listings
    cl_docs = Search::ClassifiedListing.search_documents(
      params: classified_listing_params.to_h,
    )

    render json: { result: cl_docs }
  end

  def users
    render json: { result: user_search }
  end

  def feed_content
    feed_docs = if params[:class_name].blank?
                  # If we are in the main feed and not filtering by type return
                  # all articles, podcast episodes, and users
                  feed_content_search.concat(user_search)
                elsif params[:class_name] == "User"
                  # No need to check for articles or podcast episodes if we know we only want users
                  user_search
                else
                  # if params[:class_name] == PodcastEpisode, Article, or Comment then skip user lookup
                  feed_content_search
                end

    render json: { result: feed_docs }
  end

  def reactions
    result = Search::Reaction.search_documents(
      params: reaction_params.merge(user_id: current_user.id).to_h,
    )

    render json: { result: result["reactions"], total: result["total"] }
  end

  private

  def feed_content_search
    Search::FeedContent.search_documents(params: feed_params.to_h)
  end

  def user_search
    Search::User.search_documents(params: user_params.to_h)
  end

  def chat_channel_params
    accessible = %i[
      per_page
      page
      channel_text
      channel_type
      channel_status
      status
    ]

    params.permit(accessible)
  end

  def classified_listing_params
    params.permit(CLASSIFIED_LISTINGS_PARAMS)
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
