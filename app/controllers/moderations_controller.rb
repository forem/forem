class ModerationsController < ApplicationController
  after_action :verify_authorized

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

  private

  def core_pages?
    true
  end
end
