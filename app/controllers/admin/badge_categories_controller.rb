module Admin
  class BadgeCategoriesController < Admin::ApplicationController
    layout "admin"

    before_action :set_badge_category, only: %i[edit update destroy]

    def index
      @badge_categories = BadgeCategory.order(id: :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @badge_categories = @badge_categories.where("name ILIKE :search", search: "%#{params[:search]}%")
    end

    def new
      @badge_category = BadgeCategory.new
    end

    def edit; end

    def create
      @badge_category = BadgeCategory.new(badge_category_params)

      if @badge_category.save
        flash[:success] = I18n.t("admin.badge_categories_controller.created")
        redirect_to admin_badge_categories_path
      else
        flash[:danger] = @badge_category.errors_as_sentence
        render :new
      end
    end

    def update
      if @badge_category.update(badge_category_params)
        flash[:success] = I18n.t("admin.badge_categories_controller.updated")
        redirect_to admin_badge_categories_path
      else
        flash[:danger] = @badge_category.errors_as_sentence
        render :edit
      end
    end

    def destroy
      if @badge_category.destroy
        flash[:success] = I18n.t("admin.badge_categories_controller.deleted")
        redirect_to admin_badge_categories_path
      else
        flash[:danger] = @badge_category.errors.full_messages.to_sentence
        render :edit
      end
    end

    private

    def set_badge_category
      @badge_category = BadgeCategory.find(params[:id])
    end

    def badge_category_params
      params.require(:badge_category).permit(:name, :description)
    end
  end
end
