class ArticleMutesController < ApplicationController
  after_action :verify_authorized

  def update
    @article = Article.find_by(id: params[:id])
    authorize @article
    @article.update(receive_notifications: permitted_attributes(@article)[:receive_notifications])
    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to "/dashboard" }
    end
  end
end
