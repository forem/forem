module Admin
  class ListingCategoriesController < Admin::ApplicationController
    include ListingsToolkit
    layout "admin"

    def index
      @listing_categories = ListingCategory.order(id: :desc)
        .page(params[:page]).per(50)

      return if params[:search].blank?

      @listing_categories = @listing_categories.where("name ILIKE :search", search: "%#{params[:search]}%")
    end

    def new
      @listing_category = ListingCategory.new
    end

    def edit
      @listing_category = ListingCategory.find(params[:id])
    end

    def create
      @listing_category = ListingCategory.new(listing_category_params)

      if @listing_category.save
        flash[:success] = "Listing Category has been created!"
        redirect_to admin_listing_categories_path
      else
        flash[:danger] = @listing_category.errors_as_sentence
        render :new
      end
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

    def destroy
      @listing_category = ListingCategory.find(params[:id])

      if @listing_category.destroy
        flash[:success] = "Listing Category has been deleted!"
        redirect_to admin_listing_categories_path
      else
        flash[:danger] = @listing_category.errors.full_messages.to_sentence
        render :edit
      end
    end

    private

    def listing_category_params
      params.permit(:name, :cost, :rules, :slug, :social_preview_color, :social_preview_description)
    end

    def authorize_admin
      authorize ListingCategory, :access?, policy_class: InternalPolicy
    end
  end
end
