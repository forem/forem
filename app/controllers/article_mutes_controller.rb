class ArticleMutesController < ApplicationController
  after_action :verify_authorized

  def update
    @article = Article.find_by(id: params[:id], user_id: current_user.id)
    authorize @article
    @article.update(receive_notifications: permitted_attributes(@article)[:receive_notifications])
    redirect_to "/dashboard"
  end
end
