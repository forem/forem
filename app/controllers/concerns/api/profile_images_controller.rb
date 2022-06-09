module Api
  module ProfileImagesController
    extend ActiveSupport::Concern

    def show
      not_found unless profile_image_owner

      @profile_image_owner = profile_image_owner
    end

    private

    def profile_image_owner
      user || organization
    end

    def user
      @user ||= User.registered.select(:id, :profile_image)
        .find_by(username: params[:username])
    end

    def organization
      @organization ||= Organization.select(:id, :profile_image)
        .find_by(username: params[:username])
    end
  end
end
