class ArticleApprovalsController < ApplicationController
  def create
    @article = Article.find(params[:id])
    unless current_user.any_admin?
      authorize(User, :moderation_routes?)
      @article.decorate.cached_tag_list_array.each do |tag|
        authorize(Tag.find_by(name: tag), :update?)
      end
    end
    @article.update(approved: params[:approved])
    redirect_to "#{URI.parse(@article.path).path}/mod"
  end
end
