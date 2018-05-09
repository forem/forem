class ModerationsController < ApplicationController

  before_action :check_trusted

  def article
    @moderatable = Article.find_by_slug(params[:slug])
    render template: "moderations/mod"
  end

  def comment
    @moderatable = Comment.find(params[:id_code].to_i(26))
    render template: "moderations/mod"
  end

  private

  def check_trusted
    not_found unless current_user&.has_role?(:trusted)
  end
end
