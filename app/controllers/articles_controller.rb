class ArticlesController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!, except: %i[feed new]
  before_action :set_article, only: %i[edit manage update destroy]
  before_action :raise_banned, only: %i[new create update]
  before_action :set_cache_control_headers, only: %i[feed]
  after_action :verify_authorized

  def feed
    skip_authorization

    @articles = Article.published.
      select(:published_at, :processed_html, :user_id, :organization_id, :title, :path).
      order(published_at: :desc).
      page(params[:page].to_i).per(12)

    @articles = if params[:username]
                  handle_user_or_organization_feed
                elsif params[:tag]
                  handle_tag_feed
                else
                  @articles.where(featured: true).includes(:user)
                end

    unless @articles
      render body: nil
      return
    end

    set_surrogate_key_header "feed"
    response.headers["Surrogate-Control"] = "max-age=600, stale-while-revalidate=30, stale-if-error=86400"

    render layout: false
  end

  def new
    @user = current_user
    @organization = @user&.organization
    @tag = Tag.find_by(name: params[:template])
    @prefill = params[:prefill].to_s.gsub("\\n ", "\n").gsub("\\n", "\n")
    @article = if @tag.present? && @user&.editor_version == "v2"
                 authorize Article
                 submission_template = @tag.submission_template_customized(@user.name).to_s
                 Article.new(body_markdown: submission_template.split("---").last.to_s.strip, cached_tag_list: @tag.name,
                             processed_html: "", user_id: current_user&.id, title: submission_template.split("title:")[1].to_s.split("\n")[0].to_s.strip)
               elsif @tag&.submission_template.present? && @user
                 authorize Article
                 Article.new(body_markdown: @tag.submission_template_customized(@user.name),
                             processed_html: "", user_id: current_user&.id)
               elsif @prefill.present? && @user&.editor_version == "v2"
                 authorize Article
                 Article.new(body_markdown: @prefill.split("---").last.to_s.strip, cached_tag_list: @prefill.split("tags:")[1].to_s.split("\n")[0].to_s.strip,
                             processed_html: "", user_id: current_user&.id, title: @prefill.split("title:")[1].to_s.split("\n")[0].to_s.strip)
               elsif @prefill.present? && @user
                 authorize Article
                 Article.new(body_markdown: @prefill,
                             processed_html: "", user_id: current_user&.id)
               elsif @tag.present?
                 skip_authorization
                 Article.new(
                   body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: " + @tag.name + "\n---\n\n",
                   processed_html: "", user_id: current_user&.id
                 )
               else
                 skip_authorization
                 if @user&.editor_version == "v2"
                   Article.new(user_id: current_user&.id)
                 else
                   Article.new(
                     body_markdown: "---\ntitle: \npublished: false\ndescription: \ntags: \n---\n\n",
                     processed_html: "", user_id: current_user&.id
                   )
                 end
               end
  end

  def edit
    authorize @article
    @user = @article.user
    @organization = @user&.organization
  end

  def manage
    @article = @article.decorate
    authorize @article
    @user = @article.user
    @rating_vote = RatingVote.where(article_id: @article.id, user_id: @user.id).first
    @buffer_updates = BufferUpdate.where(composer_user_id: @user.id, article_id: @article.id)
    @organization = @user&.organization
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

    @user = current_user

    respond_to do |format|
      format.html do
        @article = ArticleCreationService.
          new(@user, article_params, job_opportunity_params).
          create!

        redirect_after_creation
      end

      format.json do
        @article = ArticleCreationService.
          new(@user, article_params_json, {}).
          create!

        render json: if @article.persisted?
                       @article.to_json(only: [:id], methods: [:current_state_path])
                     else
                       @article.errors.to_json
                     end
      end
    end
  end

  def update
    authorize @article
    @user = @article.user || current_user
    @article.tag_list = []
    @article.main_image = nil
    edited_at_date = if @article.user == current_user && @article.published
                       Time.current
                     else
                       @article.edited_at
                     end
    if @article.update(article_params.merge(edited_at: edited_at_date))
      handle_org_assignment
      handle_hiring_tag
      if @article.published
        Notification.send_to_followers(@article, "Published") if @article.saved_changes["published_at"]&.include?(nil)
        path = @article.path
      else
        Notification.remove_all_without_delay(notifiable_id: @article.id, notifiable_type: "Article", action: "Published")
        path = "/#{@article.username}/#{@article.slug}?preview=#{@article.password}"
      end

      respond_to do |format|
        format.json { head :ok }
        format.html { redirect_to(params[:destination] || path) }
      end
    else
      respond_to do |format|
        format.html { redirect_to :edit }
        format.json { head :unprocessable_entity }
      end
    end
  end

  def delete_confirm
    @article = current_user.articles.find_by(slug: params[:slug])
    authorize @article
  end

  def destroy
    authorize @article
    @article.destroy!
    Notification.remove_all_without_delay(notifiable_id: @article.id, notifiable_type: "Article", action: "Published")
    Notification.remove_all(notifiable_id: @article.id, notifiable_type: "Article", action: "Reaction")
    respond_to do |format|
      format.html { redirect_to "/dashboard", notice: "Article was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def handle_org_assignment
    if @user.organization_id.present? && article_params[:publish_under_org].to_i == 1
      @article.organization_id = @user.organization_id
      @article.save
    elsif article_params[:publish_under_org].present?
      @article.organization_id = nil
      @article.save
    end
  end

  def handle_hiring_tag
    if job_opportunity_params.present? && @article.tag_list.include?("hiring")
      create_or_update_job_opportunity
    elsif @article.job_opportunity && !@article.tag_list.include?("hiring")
      @article.job_opportunity.destroy!
    end
  end

  def handle_user_or_organization_feed
    if (@user = User.find_by(username: params[:username]))
      @articles = @articles.where(user_id: @user.id)
    elsif (@user = Organization.find_by(slug: params[:username]))
      @articles = @articles.where(organization_id: @user.id).includes(:user)
    end
  end

  def handle_tag_feed
    tag = Tag.find_by(name: params[:tag].downcase)

    return unless tag

    @tag = tag.alias_for.presence || tag
    @articles = @articles.cached_tagged_with(@tag)
  end

  def create_or_update_job_opportunity
    if @article.job_opportunity.present?
      @article.job_opportunity.update(job_opportunity_params)
    else
      @job_opportunity = JobOpportunity.create(job_opportunity_params)
      @article.job_opportunity = @job_opportunity
      @article.save
    end
  end

  def set_article
    owner = User.find_by(username: params[:username]) || Organization.find_by(slug: params[:username])
    found_article = if params[:slug]
                      owner.articles.includes(:user).find_by(slug: params[:slug])
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

  def article_params_json
    params["article"].transform_keys!(&:underscore)
    params["article"]["organization_id"] = (@user.organization_id if params["article"]["post_under_org"])
    if params["article"]["series"].present?
      params["article"]["collection_id"] = Collection.find_series(params["article"]["series"], @user)&.id
    elsif params["article"]["series"] == ""
      params["article"]["collection_id"] = nil
    end
    if params["article"]["version"] == "v1"
      params.require(:article).permit(
        :body_markdown, :organization_id
      )
    else
      params.require(:article).permit(
        :title, :body_markdown, :main_image, :published, :description,
        :tag_list, :organization_id, :canonical_url, :series, :collection_id
      )
    end
  end

  def job_opportunity_params
    return nil if params[:article][:job_opportunity].blank?

    params[:article].require(:job_opportunity).permit(
      :remoteness, :location_given, :location_city, :location_postal_code,
      :location_country_code, :location_lat, :location_long
    )
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

  def org_admin_user_change_privilege
    params[:article][:user_id] &&
      current_user.org_admin &&
      current_user.organization_id == @article.organization_id &&
      User.find(params[:article][:user_id])&.organization_id == @article.organization_id
  end
end
