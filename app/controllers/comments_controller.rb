class CommentsController < ApplicationController
  before_action :set_comment, only: %i[update destroy]
  before_action :set_cache_control_headers, only: [:index]
  before_action :authenticate_user!, only: %i[preview create]
  after_action :verify_authorized

  # GET /comments
  # GET /comments.json
  def index
    skip_authorization
    @on_comments_page = true
    @comment = Comment.new
    @podcast = Podcast.find_by(slug: params[:username])

    @root_comment = Comment.find(params[:id_code].to_i(26)) if params[:id_code].present?

    if @podcast
      @user = @podcast
      (@commentable = @user.podcast_episodes.find_by(slug: params[:slug])) || not_found
    else
      @user = User.find_by(username: params[:username]) ||
        Organization.find_by(slug: params[:username]) ||
        not_found
      @commentable = @root_comment&.commentable ||
        @user.articles.find_by(slug: params[:slug]) ||
        not_found
      @article = @commentable
      not_found unless @commentable.published
    end

    @commentable_type = @commentable.class.name

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
    authorize @comment
    @parent_comment = @comment.parent
    @commentable = @comment.commentable
  end

  # POST /comments
  # POST /comments.json
  def create
    authorize Comment
    raise if RateLimitChecker.new(current_user).limit_by_situation("comment_creation")

    @comment = Comment.new(permitted_attributes(Comment))
    @comment.user_id = current_user.id

    if @comment.save
      current_user.update(checked_code_of_conduct: true) if params[:checked_code_of_conduct].present? && !current_user.checked_code_of_conduct

      Mention.create_all(@comment)
      NotificationSubscription.create(user: current_user, notifiable_id: @comment.id, notifiable_type: "Comment", config: "all_comments")
      Notification.send_new_comment_notifications_without_delay(@comment)

      if @comment.invalid?
        @comment.destroy
        render json: { status: "comment already exists" }
        return
      end

      render json: {
        status: "created",
        css: @comment.custom_css,
        depth: @comment.depth,
        url: @comment.path,
        readable_publish_date: @comment.readable_publish_date,
        published_timestamp: @comment.decorate.published_timestamp,
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
          github_username: current_user.github_username
        }
      }
    elsif (@comment = Comment.where(body_markdown: @comment.body_markdown,
                                    commentable_id: @comment.commentable.id,
                                    ancestry: @comment.ancestry)[1])
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
    authorize @comment
    if @comment.update(permitted_attributes(@comment).merge(edited_at: Time.zone.now))
      Mention.create_all(@comment)
      redirect_to @comment.path, notice: "Comment was successfully updated."
    else
      @commentable = @comment.commentable
      render :edit
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    authorize @comment
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
    @comment = Comment.find(params[:id_code].to_i(26))
    authorize @comment
  end

  def preview
    skip_authorization
    begin
      permitted_body_markdown = permitted_attributes(Comment)[:body_markdown]
      fixed_body_markdown = MarkdownFixer.fix_for_preview(permitted_body_markdown)
      parsed_markdown = MarkdownParser.new(fixed_body_markdown)
      processed_html = parsed_markdown.finalize
    rescue StandardError => e
      processed_html = "<p>😔 There was a error in your markdown</p><hr><p>#{e}</p>"
    end
    respond_to do |format|
      format.json { render json: { processed_html: processed_html }, status: :ok }
    end
  end

  def settings
    @comment = Comment.find(params[:id_code].to_i(26))
    authorize @comment
    @notification_subscription = NotificationSubscription.find_or_initialize_by(user_id: @comment.user_id, notifiable_id: @comment.id, notifiable_type: "Comment", config: "all_comments")
    render :settings
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_comment
    @comment = Comment.find(params[:id])
  end
end
