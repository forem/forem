class SocialPreviewsController < ApplicationController
  # No authorization required for entirely public controller

  def article
    @article = Article.find(params[:id])
    not_found unless @article.published
    if (@article.decorate.cached_tag_list_array & %w[shecoded theycoded shecodedally]).any?
      render "shecoded", layout: false
    else
      render layout: false
    end
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
