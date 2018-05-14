class SocialPreviewsController < ApplicationController

  def article
    @article = Article.find(params[:id])
    not_found unless @article.published
    render layout: false
  end

  def user
    @user = User.find(params[:id]) || not_found
    render layout: false
  end

  def organization
    @user = Organization.find(params[:id]) || not_found
    render "user", layout: false
  end

  def tag
    @tag = Tag.find(params[:id]) || not_found
    render layout: false
  end

end