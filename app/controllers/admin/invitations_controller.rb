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
      custom_invite_subject = params.dig(:user, :custom_invite_subject)
      custom_invite_message = params.dig(:user, :custom_invite_message)
      custom_invite_footnote = params.dig(:user, :custom_invite_footnote)

      if User.exists?(email: email.downcase, registered: true)
        flash[:error] = I18n.t("admin.invitations_controller.duplicate", email: email)
        redirect_to admin_invitations_path
        return
      end

      username = "#{email.split('@').first.gsub(/[^0-9a-z ]/i, '')}_#{rand(1000)}"
      User.invite!({ email: email,
                     username: username,
                     profile_image: ::Images::ProfileImageGenerator.call,
                     registered: false },
                   nil,
                   {
                     custom_invite_subject: custom_invite_subject,
                     custom_invite_message: custom_invite_message,
                     custom_invite_footnote: custom_invite_footnote
                   })
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

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:invite,
                                        keys: %i[email
                                                 name
                                                 username
                                                 custom_invite_subject
                                                 custom_invite_message
                                                 custom_invite_footnote
                                                 profile_image
                                                 registered])
    end
  end
end
