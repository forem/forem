class HtmlVariantsController < ApplicationController
  after_action :verify_authorized

  def index
    authorize HtmlVariant
    @user_variants = current_user.html_variants.order("created_at DESC")
    @all_published_variants = HtmlVariant.where(published: true).order("created_at DESC")
    @preview_path = Article.where(featured: true, published: true).order("published_at DESC").first&.path.to_s
  end

  def new
    authorize HtmlVariant
    @html_variant = HtmlVariant.new
    if params[:fork_id]
      @fork = HtmlVariant.find(params[:fork_id])
      @html_variant.name = @fork.name + " FORK"
      @html_variant.html = @fork.html
    end
  end

  def edit
    @html_variant = HtmlVariant.find(params[:id])
    authorize @html_variant
  end

  def create
    authorize HtmlVariant
    @html_variant = HtmlVariant.new(html_variant_params)
    @html_variant.group = "article_show_sidebar_cta"
    @html_variant.user_id = current_user.id
    if @html_variant.save
      redirect_to "/html_variants"
    else
      render :new
    end
  end

  def update
    @html_variant = HtmlVariant.find(params[:id])
    authorize @html_variant
    if @html_variant.update(html_variant_params)
      redirect_to "/html_variants"
    else
      render :edit
    end
  end

  private

  def html_variant_params
    params.require(:html_variant).permit(policy(HtmlVariant).permitted_attributes)
  end
end
