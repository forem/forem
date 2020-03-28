class ArticlesController < ApplicationController
  include ApplicationHelper

  before_action :authenticate_user!, except: %i[feed new]
  before_action :set_article, only: %i[edit manage update destroy stats]
  before_action :raise_suspended, only: %i[new create update]
  before_action :set_cache_control_headers, only: %i[feed]
  after_action :verify_authorized

  def feed
    skip_authorization

    @articles = Article.feed.order(published_at: :desc).page(params[:page].to_i).per(12)
    @articles = if params[:username]
                  handle_user_or_organization_feed
                elsif params[:tag]
                  handle_tag_feed
                else
                  @articles.where(featured: true).includes(:user)
                end

    unless @articles&.any?
      not_found
    end

    set_surrogate_key_header "feed"
    response.headers["Surrogate-Control"] = "max-age=600, stale-while-revalidate=30, stale-if-error=86400"

    render layout: false
  end

  def new
    base_editor_assigments
    @article = if @tag.present? && @user&.editor_version == "v2"
                 authorize Article
                 submission_template = @tag.submission_template_customized(@user.name).to_s
                 Article.new(
                   body_markdown: submission_template.split("---").last.to_s.strip,
                   cached_tag_list: @tag.name,
                   processed_html: "",
                   user_id: current_user&.id,
                   title: submission_template.split("title:")[1].to_s.split("\n")[0].to_s.strip,
                 )
               elsif @tag&.submission_template.present? && @user
                 authorize Article
                 Article.new(
                   body_markdown: @tag.submission_template_customized(@user.name),
                   processed_html: "",
                   user_id: current_user&.id,
                 )
               elsif @prefill.present? && @user&.editor_version == "v2"
                 authorize Article
                 Article.new(
                   body_markdown: @prefill.split("---").last.to_s.strip,
                   cached_tag_list: @prefill.split("tags:")[1].to_s.split("\n")[0].to_s.strip,
                   processed_html: "",
                   user_id: current_user&.id,
                   title: @prefill.split("title:")[1].to_s.split("\n")[0].to_s.strip,
                 )
               elsif @prefill.present? && @user
                 authorize Article
                 Article.new(
                   body_markdown: @prefill,
                   processed_html: "",
                   user_id: current_user&.id,
                 )
               elsif @tag.present?
                 skip_authorization
                 Article.new(
                   body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: #{@tag.name}\n---\n\n",
                   processed_html: "",
                   user_id: current_user&.id,
                 )
               else
                 skip_authorization
                 if @user&.editor_version == "v2"
                   Article.new(user_id: current_user&.id)
                 else
                   Article.new(
                     body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: \n---\n\n",
                     processed_html: "",
                     user_id: current_user&.id,
                   )
                 end
               end
  end

  def edit
    authorize @article

    @version = @article.has_frontmatter? ? "v1" : "v2"
    @user = @article.user
    @organizations = @user&.organizations
  end

  def manage
    authorize @article

    @article = @article.decorate
    @user = @article.user
    @rating_vote = RatingVote.where(article_id: @article.id, user_id: @user.id).first
    @buffer_updates = BufferUpdate.where(composer_user_id: @user.id, article_id: @article.id)
    @organizations = @user&.organizations
    # TODO: fix this for multi orgs
    @org_members = @organization.users.pluck(:name, :id) if @organization
  end

  def preview
    authorize Article

    begin
      fixed_body_markdown = MarkdownFixer.fix_for_preview(params[:article_body])
      parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
      parsed_markdown = MarkdownParser.new(parsed.content)
      processed_html = parsed_markdown.finalize
    rescue StandardError => e
      @article = Article.new(body_markdown: params[:article_body])
      @article.errors[:base] << ErrorMessageCleaner.new(e.message).clean
    end

    respond_to do |format|
      if @article
        format.json { render json: @article.errors, status: :unprocessable_entity }
      else
        format.json do
          render json: {
            processed_html: processed_html,
            title: parsed["title"],
            tags: (Article.new.tag_list.add(parsed["tags"], parser: ActsAsTaggableOn::TagParser) if parsed["tags"]),
            cover_image: (ApplicationController.helpers.cloud_cover_url(parsed["cover_image"]) if parsed["cover_image"])
          }
        end
      end
    end
  end

  def create
    authorize Article

    article = Articles::Creator.call(current_user, article_params_json)

    render json: if article.persisted?
                   { id: article.id, current_state_path: article.decorate.current_state_path }.to_json
                 else
                   article.errors.to_json
                 end
  end

  def update
    authorize @article
    @user = @article.user || current_user

    not_found if @article.user_id != @user.id && !@user.has_role?(:super_admin)

    edited_at_date = if @article.user == current_user && @article.published
                       Time.current
                     else
                       @article.edited_at
                     end
    updated = @article.update(article_params_json.merge(edited_at: edited_at_date))
    handle_notifications(updated)
    Webhook::DispatchEvent.call("article_updated", @article) if updated
    respond_to do |format|
      format.html do
        # TODO: JSON should probably not be returned in the format.html section
        if article_params_json[:archived] && @article.archived # just to get archived working
          render json: @article.to_json(only: [:id], methods: [:current_state_path])
          return
        end
        if params[:destination]
          redirect_to(URI.parse(params[:destination]).path)
          return
        end
        if params[:article][:video_thumbnail_url]
          redirect_to(@article.path + "/edit")
          return
        end
        render json: { status: 200 }
      end

      format.json do
        render json: if updated
                       @article.to_json(only: [:id], methods: [:current_state_path])
                     else
                       @article.errors.to_json
                     end
      end
    end
  end

  def delete_confirm
    @article = current_user.articles.find_by(slug: params[:slug])
    not_found unless @article
    authorize @article
  end

  def destroy
    authorize @article
    Articles::Destroyer.call(@article)
    respond_to do |format|
      format.html { redirect_to "/dashboard", notice: "Article was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def stats
    authorize current_user, :pro_user?
    authorize @article
    @organization_id = @article.organization_id
  end

  private

  def base_editor_assigments
    @user = current_user
    @version = @user.editor_version if @user
    @organizations = @user&.organizations
    @tag = Tag.find_by(name: params[:template])
    @prefill = params[:prefill].to_s.gsub("\\n ", "\n").gsub("\\n", "\n")
  end

  def handle_user_or_organization_feed
    if (@user = User.find_by(username: params[:username]))
      @articles = @articles.where(user_id: @user.id)
    elsif (@user = Organization.find_by(slug: params[:username]))
      @articles = @articles.where(organization_id: @user.id).includes(:user)
    end
  end

  def handle_tag_feed
    @tag = Tag.aliased_name(params[:tag])
    return unless @tag

    @articles = @articles.cached_tagged_with(@tag)
  end

  def set_article
    owner = User.find_by(username: params[:username]) || Organization.find_by(slug: params[:username])
    found_article = if params[:slug] && owner
                      owner.articles.find_by(slug: params[:slug])
                    else
                      Article.includes(:user).find(params[:id])
                    end
    @article = found_article || not_found
  end

  def article_params
    params[:article][:published] = true if params[:submit_button] == "PUBLISH"
    modified_params = policy(Article).permitted_attributes
    modified_params << :user_id if org_admin_user_change_privilege
    modified_params << :comment_template if current_user.has_role?(:admin)
    params.require(:article).permit(modified_params)
  end

  # TODO: refactor all of this update logic into the Articles::Updater possibly,
  # ideally there should only be one place to handle the update logic
  def article_params_json
    params.require(:article) # to trigger the correct exception in case `:article` is missing

    params["article"].transform_keys!(&:underscore)

    # handle series/collections
    if params["article"]["series"].present?
      collection = Collection.find_series(params["article"]["series"], @user)
      params["article"]["collection_id"] = collection.id
    elsif params["article"]["series"] == "" # reset collection?
      params["article"]["collection_id"] = nil
    end

    allowed_params = if params["article"]["version"] == "v1"
                       %i[body_markdown]
                     else
                       %i[
                         title body_markdown main_image published description video_thumbnail_url
                         tag_list canonical_url series collection_id archived
                       ]
                     end

    # NOTE: the organization logic is still a little counter intuitive but this should
    # fix the bug <https://github.com/thepracticaldev/dev.to/issues/2871>
    if params["article"]["user_id"] && org_admin_user_change_privilege
      allowed_params << :user_id
    elsif params["article"]["organization_id"] && allowed_to_change_org_id?
      # change the organization of the article only if explicitly asked to do so
      allowed_params << :organization_id
    end

    params.require(:article).permit(allowed_params)
  end

  def handle_notifications(updated)
    if updated && @article.published && @article.saved_changes["published"] == [false, true]
      Notification.send_to_followers(@article, "Published")
    elsif @article.saved_changes["published"] == [true, false]
      Notification.remove_all_by_action_without_delay(notifiable_ids: @article.id, notifiable_type: "Article", action: "Published")
      Notification.remove_all(notifiable_ids: @article.comments.pluck(:id), notifiable_type: "Comment") if @article.comments.exists?
    end
  end

  def redirect_after_creation
    @article.decorate
    if @article.persisted?
      redirect_to @article.current_state_path, notice: "Article was successfully created."
    else
      if @article.errors.to_h[:body_markdown] == "has already been taken"
        @article = current_user.articles.find_by(body_markdown: @article.body_markdown)
        redirect_to @article.current_state_path
        return
      end
      render :new
    end
  end

  def allowed_to_change_org_id?
    potential_user = @article&.user || current_user
    potential_org_id = params["article"]["organization_id"].presence || @article&.organization_id
    OrganizationMembership.exists?(user: potential_user, organization_id: potential_org_id) ||
      current_user.any_admin?
  end

  def org_admin_user_change_privilege
    params[:article][:user_id] &&
      # if current_user is an org admin of the article's org
      current_user.org_admin?(@article.organization_id) &&
      # and if the author being changed to belongs to the article's org
      OrganizationMembership.exists?(user_id: params[:article][:user_id], organization_id: @article.organization_id)
  end
end
