class HtmlVariantsController < ApplicationController
  after_action :verify_authorized

  def index
    authorize HtmlVariant
    @html_variants = if params[:state] == "mine"
                       current_user.html_variants.order("created_at DESC").includes(:user).page(params[:page]).per(30)
                     elsif params[:state] == "admin"
                       HtmlVariant.where(published: true, approved: false).order("created_at DESC").includes(:user).page(params[:page]).per(30)
                     elsif params[:state].present?
                       HtmlVariant.where(published: true, approved: true, group: params[:state]).order("success_rate DESC").includes(:user).page(params[:page]).per(30)
                     else
                       HtmlVariant.where(published: true, approved: true).order("success_rate DESC").includes(:user).page(params[:page]).per(30)
                     end
  end

  def new
    authorize HtmlVariant
    @html_variant = HtmlVariant.new
    return unless params[:fork_id]

    @fork = HtmlVariant.find(params[:fork_id])
    @html_variant.name = @fork.name + " FORK-#{rand(10_000)}"
    @html_variant.html = @fork.html
  end

  def show
    @story_show = true
    @article_show = true
    @html_variant = HtmlVariant.find(params[:id])
    authorize @html_variant
    render layout: false
  end

  def edit
    @html_variant = HtmlVariant.find(params[:id])
    authorize @html_variant
  end

  def create
    authorize HtmlVariant
    @html_variant = HtmlVariant.new(html_variant_params)
    @html_variant.user_id = current_user.id
    if @html_variant.save
      flash[:success] = "HTML Variant Created"
      redirect_to "/html_variants/#{@html_variant.id}/edit"
    else
      render :new
    end
  end

  def update
    @html_variant = HtmlVariant.find(params[:id])
    authorize @html_variant
    if @html_variant.update(html_variant_params)
      flash[:success] = "HTML Variant Updated"
      redirect_to "/html_variants/#{@html_variant.id}/edit"
    else
      render :edit
    end
  end

  private

  def html_variant_params
    params.require(:html_variant).permit(policy(HtmlVariant).permitted_attributes)
  end
end
