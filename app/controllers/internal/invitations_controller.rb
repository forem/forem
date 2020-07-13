module Internal
  class InvitationsController < Internal::ApplicationController
    layout "internal"

    def index
      @invitations = User.where(registered: false).page(params[:page]).per(50)
    end

    def new; end

    def create
      email = params[:user][:email]
      name = params[:user][:name]
      username = name.downcase.tr(" ", "_") + rand(1000).to_s
      User.invite!(email: email,
                   name: name,
                   username: username,
                   remote_profile_image_url: "https://dev-to-uploads.s3.amazonaws.com/uploads/user/profile_image/1/f451a206-11c8-4e3d-8936-143d0a7e65bb.png",
                   registered: false)
      redirect_to "/internal/invitations"
    end
  end
end
