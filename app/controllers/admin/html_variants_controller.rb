module Admin
  class HtmlVariantsController < Admin::ApplicationController
    layout "admin"

    def index
      relation = if params[:state] == "mine"
                   current_user.html_variants.order(created_at: :desc)
                 elsif params[:state].present? && params[:state] != "admin"
                   HtmlVariant.where(published: true, approved: true, group: params[:state]).order(created_at: :desc)
                 else
                   HtmlVariant.where(published: true, approved: true).order(created_at: :desc)
                 end

      @html_variants = relation.includes(:user).page(params[:page]).per(30)
    end

    def new
      @html_variant = HtmlVariant.new
      return unless params[:fork_id]

      @fork = HtmlVariant.find(params[:fork_id])
      @html_variant.name = I18n.t("admin.html_variants_controller.fork", name: @fork.name, rand: rand(10_000))
      @html_variant.html = @fork.html
    end

    def show
      @html_variant = HtmlVariant.find(params[:id])
      render layout: "application"
    end

    def edit
      @html_variant = HtmlVariant.find(params[:id])
    end

    def create
      @html_variant = HtmlVariant.new(html_variant_params)
      @html_variant.user_id = current_user.id

      if @html_variant.save
        flash[:success] = I18n.t("admin.html_variants_controller.created")
        redirect_to admin_html_variants_path(state: "mine")
      else
        flash[:danger] = @html_variant.errors_as_sentence
        render :new
      end
    end

    def update
      @html_variant = HtmlVariant.find(params[:id])

      if @html_variant.update(html_variant_params)
        flash[:success] = I18n.t("admin.html_variants_controller.updated")
        redirect_to edit_admin_html_variant_path(@html_variant)
      else
        flash[:danger] = @html_variant.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @html_variant = HtmlVariant.find(params[:id])

      if @html_variant.destroy
        flash[:success] = I18n.t("admin.html_variants_controller.deleted")
        redirect_to admin_html_variants_path
      else
        flash[:danger] = I18n.t("admin.html_variants_controller.wrong")
        render :edit
      end
    end

    private

    def html_variant_params
      params.permit(:html, :name, :published, :approved, :target_tag, :group)
    end

    def authorize_admin
      authorize HtmlVariant, :access?, policy_class: InternalPolicy
    end
  end
end
