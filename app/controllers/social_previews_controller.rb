class SocialPreviewsController < ApplicationController

  def show
    @article = Article.find(params[:id])
    not_found unless @article.published
    render layout: false
  end

end