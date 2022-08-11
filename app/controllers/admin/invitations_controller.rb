module Admin
  class InvitationsController < Admin::ApplicationController
    layout "admin"

    def index
      @invitations = Admin::UsersQuery.call(
        relation: User.invited,
        search: params[:search],
        role: params[:role],
        roles: params[:roles],
      ).page(params[:page]).per(50)
    end

    def new; end

    def create
      email = params.dig(:user, :email)

      if User.exists?(email: email.downcase, registered: true)
        flash[:error] = I18n.t("admin.invitations_controller.duplicate", email: email)
        redirect_to admin_invitations_path
        return
      end

      username = "#{email.split('@').first.gsub(/[^0-9a-z ]/i, '')}_#{rand(1000)}"
      User.invite!(email: email,
                   username: username,
                   remote_profile_image_url: ::Users::ProfileImageGenerator.call,
                   registered: false)
      flash[:success] = I18n.t("admin.invitations_controller.create_success")
      redirect_to admin_invitations_path
    end

    def destroy
      @invitation = User.where(registered: false).find(params[:id])
      if @invitation.destroy
        flash[:success] = I18n.t("admin.invitations_controller.destroy_success", email: @invitation.email)
      else
        flash[:danger] = @invitation.errors_as_sentence
      end
      redirect_to admin_invitations_path
    end

    def resend
      @invited_user = User.where(registered: false).find(params[:id])
      if @invited_user.invite!
        flash[:success] = I18n.t("admin.invitations_controller.resend_success", email: @invited_user.email)
      else
        flash[:danger] = @invited_user.errors_as_sentence
      end
      redirect_to admin_invitations_path
    end
  end
end
