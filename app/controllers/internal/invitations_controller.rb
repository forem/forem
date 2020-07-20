module Internal
  class InvitationsController < Internal::ApplicationController
    layout "internal"

    def index
      @invitations = User.where(registered: false).page(params[:page]).per(50)
    end

    def new; end

    def create
      email = params.dig(:user, :email)
      name = params.dig(:user, :name)
      username = "#{name.downcase.tr(' ', '_').gsub(/[^0-9a-z ]/i, '')}_#{rand(1000)}"
      User.invite!(email: email,
                   name: name,
                   username: username,
                   remote_profile_image_url: Users::ProfileImageGenerator.call,
                   registered: false)
      redirect_to internal_invitations_path
    end
  end
end
