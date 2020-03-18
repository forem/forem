class SearchController < ApplicationController
  before_action :authenticate_user!
  before_action :format_integer_params
  before_action :sanitize_params, only: %i[classified_listings]

  CLASSIFIED_LISTINGS_PARAMS = %i[
    category
    classified_listing_search
    page
    per_page
    tags
  ].freeze

  USER_PARAMS = %i[
    search_fields
    page
    per_page
  ].freeze

  def tags
    tag_docs = Search::Tag.search_documents("name:#{params[:name]}* AND supported:true")

    render json: { result: tag_docs }
  rescue Search::Errors::Transport::BadRequest
    render json: { result: [] }
  end

  def chat_channels
    ccm_docs = Search::ChatChannelMembership.search_documents(
      params: chat_channel_params.to_h, user_id: current_user.id,
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
    user_docs = Search::User.search_documents(params: user_params.to_h)

    render json: { result: user_docs }
  end

  private

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
