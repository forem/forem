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
                   remote_profile_image_url: Users::ProfileImageGenerator.call,
                   registered: false)
      redirect_to "/internal/invitations"
    end
  end
end
