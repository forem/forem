class ChatCommentsController < ApplicationController
  def index
    @article = Article.find(params[:article_id])
    
    # We explicitly avoid standard nested trees here mathematically. We only want:
    # 1. Top-level comments ordered chronologically
    # 2. Within those, 1 level of sub-comments ordered chronologically
    
    @comments_to_show_count = 50 
    @top_level_comments = @article.comments
                                  .where(ancestry: nil, deleted: false)
                                  .order(created_at: :asc)
                                  .includes(:user)
    
    render partial: "articles/chat_comment_area", layout: false
  end
end
