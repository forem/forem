class Internal::CommentsController < Internal::ApplicationController
  layout 'internal'
  skip_before_action :verify_authenticity_token

  def index
    if params[:state]&.start_with?("toplast-")
      @comments = Comment.
        includes(:user).
        includes(:commentable).
        includes(:reactions).
        order("positive_reactions_count DESC").
        where("created_at > ?", params[:state].split("-").last.to_i.days.ago).
        page(params[:page] || 1).per(50)
    else
      @comments = Comment
                  .includes(:user)
                  .includes(:commentable)
                  .includes(:reactions)
                  .order("created_at DESC")
                  .page(params[:page] || 1).per(50)
    end
  end

  def update
    @comment = Comment.find(params[:id])
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to "/internal/comments", notice: 'This comment was updated.' }
        format.json { head :no_content }
      else
        format.html { render :index }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      params.require(:comment).permit(:article_conversion_inquiry,
                                      :article_conversion_won,
                                      :article_conversion_lost)
    end


end
