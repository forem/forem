class ModerationsController < ApplicationController
  after_action :verify_authorized

  def index
    skip_authorization
    return unless current_user&.trusted

    @articles = Article.where(published: true).
      includes(:rating_votes).
      where("rating_votes_count < 3").
      where("score > -5").
      order("hotness_score DESC").limit(50)
    if params[:tag].present?
      @articles = @articles.
        cached_tagged_with(params[:tag])
    end
    @articles = @articles.decorate
  end

  def article
    authorize(User, :moderation_routes?)
    @moderatable = Article.find_by_slug(params[:slug])
    render template: "moderations/mod"
  end

  def comment
    authorize(User, :moderation_routes?)
    @moderatable = Comment.find(params[:id_code].to_i(26))
    render template: "moderations/mod"
  end
end
