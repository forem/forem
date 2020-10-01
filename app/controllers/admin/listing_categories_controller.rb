module Admin
  class ListingCategoriesController < Admin::ApplicationController
    include ListingsToolkit
    layout "admin"

    def index
      @listing_categories = ListingCategory.order(id: :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      # @listing_categories = @listing_categories.where("organizations.name ILIKE :search",
      # search: "%#{params[:search]}%")
    end

    def new; end

    def edit
      @listing_category = ListingCategory.find(params[:id])
    end

    def update
      @listing_category = ListingCategory.find(params[:id])

      if @listing_category.update(listing_category_params)
        flash[:success] = "Listing Category has been updated!"
        redirect_to admin_listing_categories_path
      else
        flash[:danger] = @listing_category.errors_as_sentence
        render :edit
      end
    end

    def create; end

    def destroy; end

    private

    def listing_category_params
      params.permit(:name, :cost, :rules, :slug, :social_preview_color, :social_preview_description)
    end
  end
end
