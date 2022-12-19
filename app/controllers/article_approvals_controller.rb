class ArticleApprovalsController < ApplicationController
  def create
    @article = Article.find(params[:id])
    unless current_user.any_admin?
      # Check that the article can be moderated by the user
      authorize(@article, :moderate?)
      tags = @article.decorate.tags
      # Raise if no tags require approval to begin with
      raise Pundit::NotAuthorizedError unless tags.pluck(:requires_approval).include?(true)

      # Raise if user is not authorized to approve any tag that requires approval.
      tags.each do |tag|
        authorize(Tag.find(tag.id), :update?) if tag.requires_approval
      end
    end
    @article.update(approved: params[:approved])
    redirect_to "#{Addressable::URI.parse(@article.path).path}/mod"
  end
end
