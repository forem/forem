module Admin
  class BadgesController < Admin::ApplicationController
    layout "admin"

    def index
      @badges = Badge.all
    end

    def new
      @badge = Badge.new
    end

    def edit
      @badge = Badge.find(params[:id])
    end

    def create
      @badge = Badge.new(badge_params)

      if @badge.save
        flash[:success] = "Badge has been created!"
        if FeatureFlag.enabled?(:admin_restructure)
          redirect_to admin_content_manager_badges_path
        else
          redirect_to admin_badges_path
        end
      else
        flash[:danger] = @badge.errors_as_sentence
        if FeatureFlag.enabled?(:admin_restructure)
          render new_admin_content_manager_badge_path
        else
          render new_admin_badge_path
        end
      end
    end

    def update
      @badge = Badge.find(params[:id])

      if @badge.update(badge_params)
        flash[:success] = "Badge has been updated!"
        if FeatureFlag.enabled?(:admin_restructure)
          redirect_to admin_content_manager_badges_path
        else
          redirect_to admin_badges_path
        end
      else
        flash[:danger] = @badge.errors_as_sentence
        render :edit
      end
    end

    private

    def badge_params
      params.require(:badge).permit(:title, :slug, :description, :badge_image)
    end
  end
end
