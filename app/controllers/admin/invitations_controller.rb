module Admin
  class InvitationsController < Admin::ApplicationController
    layout "admin"

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
                   saw_onboarding: false,
                   editor_version: :v2,
                   registered: false)
      redirect_to admin_invitations_path
    end

    def destroy
      # User.where(registered: false).each do |invitation|
      # @invitations.each do |invitation|
      invitation = User.where(registered: false)
      if invitation.destroy
        flash[:success] = "Invitation has been deleted!"
      else
        flash[:danger] = invitation.errors_as_sentence
        redirect_to admin_invitations_path
        # end
      end
    end
  end
end
