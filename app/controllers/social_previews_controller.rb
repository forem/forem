class SocialPreviewsController < ApplicationController
  # No authorization required for entirely public controller

  def article
    @article = Article.find(session[:id])
    not_found unless @article.published
    render layout: false
  end

  def user
    @user = User.find(session[:id]) || not_found
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
