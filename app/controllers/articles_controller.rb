class ArticlesController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!, except: %i[feed new]
  before_action :set_article, only: %i[edit update destroy]
  before_action :raise_banned, only: %i[new create update]
  before_action :set_cache_control_headers, only: %i[feed]
  after_action :verify_authorized

  def feed
    skip_authorization
    @page = params[:page].to_i
    if params[:username]
      if @user = User.find_by_username(params[:username])
        @articles = Article.where(published: true, user_id: @user.id).
          includes(:user).
          select(:published_at, :slug, :processed_html, :user_id, :organization_id, :title).
          order("published_at DESC").
          page(@page).per(15)
      elsif @user = Organization.find_by_slug(params[:username])
        @articles = Article.where(published: true, organization_id: @user.id).
          includes(:user).
          select(:published_at, :slug, :processed_html, :user_id, :organization_id, :title).
          order("published_at DESC").
          page(@page).per(15)
      else
        render body: nil
        return
      end
    else
      @articles = Article.where(published: true, featured: true).
        includes(:user).
        select(:published_at, :slug, :processed_html, :user_id, :organization_id, :title).
        order("published_at DESC").
        page(@page).per(15)
    end
    set_surrogate_key_header "feed", @articles.map(&:record_key)
    response.headers["Surrogate-Control"] = "max-age=600, stale-while-revalidate=30, stale-if-error=86400"
    render layout: false
  end

  def new
    @user = current_user
    @organization = @user&.organization
    @tag = Tag.find_by_name(params[:template])
    @article = if @tag.present? && @user&.editor_version == "v2"
                 authorize Article
                 Article.new(body_markdown: "", cached_tag_list: @tag.name,
                             processed_html: "", user_id: current_user&.id)
               elsif @tag&.submission_template.present? && @user
                 authorize Article
                 Article.new(body_markdown: @tag.submission_template_customized(@user.name),
                             processed_html: "", user_id: current_user&.id)
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
        format.json { render json: { processed_html: processed_html, title: parsed["title"] }, status: 200 }
      end
    end
  end

  def create
    authorize Article
    @user = current_user
    @article = ArticleCreationService.
      new(@user, article_params, job_opportunity_params).
      create!
    redirect_after_creation
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
        Notification.send_to_followers(@article, @user.followers, "Published") if @article.saved_changes["published_at"]&.include?(nil)
        path = @article.path
      else
        Notification.remove_all(id: @article.id, class_name: "Article", action: "Published")
        path = "/#{@article.username}/#{@article.slug}?preview=#{@article.password}"
      end
      redirect_to (params[:destination] || path)
    else
      render :edit
    end
  end

  def delete_confirm
    @article = current_user.articles.find_by_slug(params[:slug])
    authorize @article
  end

  def destroy
    authorize @article
    @article.destroy!
    Notification.remove_all(id: @article.id, class_name: "Article", action: "Published")
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
    owner = User.find_by_username(params[:username]) || Organization.find_by_slug(params[:username])
    found_article = if params[:slug]
                      owner.articles.includes(:user).find_by_slug(params[:slug])
                    else
                      Article.includes(:user).find(params[:id])
                    end
    @article = found_article || not_found
  end

  def article_params
    params[:article][:published] = true if params[:submit_button] == "PUBLISH"
    params.require(:article).permit(policy(Article).permitted_attributes)
  end

  def job_opportunity_params
    return nil unless params[:article][:job_opportunity].present?
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
        @article = Article.find_by_body_markdown(@article.body_markdown)
        redirect_to @article.current_state_path
        return
      end
      render :new
    end
  end
end
