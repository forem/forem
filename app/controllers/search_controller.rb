class SearchController < ApplicationController
  before_action :authenticate_user!

  def tags
    tag_docs = Search::Tag.search_documents("name:#{params[:name]}* AND supported:true")

    render json: { result: tag_docs }
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest
    DataDogStatsClient.increment("elasticsearch.errors", tags: ["error:BadRequest"])
    render json: { result: [] }
  end
end
