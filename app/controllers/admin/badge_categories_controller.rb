module Admin
  class BadgeCategoriesController < Admin::ApplicationController
    layout "admin"

    def index
      @badge_categories = BadgeCategory.order(id: :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @badge_categories = @badge_categories.where("name ILIKE :search", search: "%#{params[:search]}%")
    end
  end
end
