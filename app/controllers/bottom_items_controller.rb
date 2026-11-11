class BottomItemsController < ApplicationController
  before_action :set_cache_control_headers, only: %i[index]

  def index
    @article = Article.find_by(id: params[:article_id])
    article_key = @article&.record_key || ("articles/#{params[:article_id].to_i}" if params[:article_id].present?)
    set_surrogate_key_header(
      article_key,
      *@article&.user&.profile_identity_cache_keys,
      @article&.organization&.record_key,
    )
    render plain: "" and return unless @article&.published

    @organization = @article.organization
    @user = @article.user
    render layout: false
  end
end
