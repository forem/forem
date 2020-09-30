module Admin
  class ListingCategoriesController < Admin::ApplicationController
    include ListingsToolkit
    layout "admin"

    def index
      @listing_categories = ListingCategory.order(id: :desc)
        # .joins(:organization)
        # .includes([:organization])
        .page(params[:page]).per(50)

      return if params[:search].blank?

      # @listing_categories = @listing_categories.where("organizations.name ILIKE :search",
      # search: "%#{params[:search]}%")
    end

    def new; end

    def edit; end

    def create; end

    def update; end

    def destroy; end
  end
end
