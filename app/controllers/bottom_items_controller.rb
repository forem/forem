class BottomItemsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index]

  def index
    @article = Article.find_by(id: params[:article_id])
    render plain: "" and return unless @article&.published
    @organization = @article.organization
    @user = @article.user
    render layout: false
  end
end
