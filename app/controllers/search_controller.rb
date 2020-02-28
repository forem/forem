class SearchController < ApplicationController
  before_action :authenticate_user!

  CLASSIFIED_LISTINGS_PARAMS = %i[
    category
    classified_listing_search
    page
    per_page
    tags
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
    params[:page] = params[:page].to_i if params[:page].present?
    params[:per_page] = params[:per_page].to_i if params[:per_page].present?
    params.permit(accessible)
  end

  def classified_listing_params
    params[:page] = params[:page].to_i if params[:page].present?
    params[:per_page] = params[:per_page].to_i if params[:per_page].present?
    params.permit(CLASSIFIED_LISTINGS_PARAMS)
  end
end
