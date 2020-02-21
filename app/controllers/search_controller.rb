class SearchController < ApplicationController
  before_action :authenticate_user!

  def tags
    tag_docs = Search::Tag.search_documents("name:#{params[:name]}* AND supported:true")

    render json: { result: tag_docs }
  end
end
