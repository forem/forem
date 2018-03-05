class CommentsController < ApplicationController
  before_action :set_comment, only: [ :update, :destroy]
  before_action :set_cache_control_headers, only: [:index]
  before_action :raise_banned, only: [:create,:update]

  # GET /comments
  # GET /comments.json
  def index
    @on_comments_page = true
    @comment = Comment.new
    @podcast = Podcast.find_by_slug(params[:username])

    if params[:id_code].present?
      @root_comment = Comment.find(params[:id_code].to_i(26))
    end

    if @podcast
      @user = @podcast
      @commentable = @user.podcast_episodes.find_by_slug(params[:slug]) or not_found
    else
      @user = User.find_by_username(params[:username]) ||
        Organization.find_by_slug(params[:username]) ||
        not_found
      @commentable = @root_comment&.commentable ||
        @user.articles.find_by_slug(params[:slug]) ||
        not_found
      @article = @commentable
    end
    @commentable_type = @commentable.class.name
    if params[:id_code].present?
      @root_comment = Comment.find(params[:id_code].to_i(26))
    end

    set_surrogate_key_header "comments-for-#{@commentable.id}-#{@commentable_type}"
  end

  # GET /comments/1
  # GET /comments/1.json
  # def show
  #   @comment = Comment.find_by_id_code(params[:id_code])
  # end

  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id_code].to_i(26))
    not_found unless current_user && current_user.id == @comment.user_id
    @parent_comment = @comment.parent
    @commentable = @comment.commentable
  end

  # POST /comments
  # POST /comments.json
  def create
    csrf_logger_info("comment creation")
    unless current_user
      redirect_to "/"
      return
    end
    raise if RateLimitChecker.new(current_user).limit_by_situation("comment_creation")
    @comment = Comment.new(comment_params)
    @comment.user_id = current_user.id
    if @comment.save
      if params[:checked_code_of_conduct].present? && !current_user.checked_code_of_conduct
        current_user.update(checked_code_of_conduct: true)
      end
      Mention.create_all(@comment)
      if @comment.invalid?
        @comment.destroy
        render json: { status: "comment already exists" }
        return
      end
      render json: {  status: "created",
                      css: @comment.custom_css,
                      depth: @comment.depth,
                      url: @comment.path,
                      readable_publish_date: @comment.readable_publish_date,
                      body_html: @comment.processed_html,
                      id: @comment.id,
                      id_code: @comment.id_code_generated,
                      newly_created: true,
                      user: {
                        id: current_user.id,
                        username: current_user.username,
                        name: current_user.name,
                        profile_pic: ProfileImage.new(current_user).get(50),
                        twitter_username: current_user.twitter_username,
                        github_username: current_user.github_username,
                      } }
    elsif @comment = Comment.where(body_markdown: @comment.body_markdown,
                                   commentable_id: @comment.commentable.id,
                                   ancestry: @comment.ancestry)[1]
      @comment.destroy
      render json: { status: "comment already exists" }
      return
    else
      render json: { status: "errors" }
      return
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update
    raise unless @comment.user_id == current_user.id
    if @comment.update(comment_update_params.merge({ edited_at: DateTime.now }))
      Mention.create_all(@comment)
      redirect_to "#{@comment.commentable.path}/comments/#{@comment.id_code_generated}", notice: "Comment was successfully updated."
    else
      @commentable = @comment.commentable
      render :edit
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    raise unless @comment.user_id == current_user.id
    @commentable_path = @comment.commentable.path
    if @comment.is_childless?
      @comment.destroy
    else
      @comment.deleted = true
      @comment.save!
    end
    redirect_to @commentable_path, notice: "Comment was successfully deleted."
  end

  def delete_confirm
    unless current_user && Comment.where(id: params[:id_code].to_i(26), user_id: current_user.id ).first
      @comment = Comment.find(params[:id_code].to_i(26))
      redirect_to @comment.path
      return
    end
    @comment = Comment.where(id: params[:id_code].to_i(26), user_id: current_user.id ).first
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      params.require(:comment).permit(:body_markdown,
                                      :commentable_id,
                                      :commentable_type,
                                      :parent_id)
    end

    def comment_update_params
      params.require(:comment).permit(:body_markdown)
    end
end
