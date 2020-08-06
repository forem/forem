module Admin
  class UsersController < Admin::ApplicationController
    layout "admin"

    after_action only: %i[update user_status banish full_delete merge] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def index
      @users = Admin::UsersQuery.call(
        options: params.permit(:role, :search),
      ).page(params[:page]).per(50)
    end

    def edit
      @user = User.find(params[:id])
      @notes = @user.notes.order(created_at: :desc).limit(10).load
    end

    def show
      @user = User.find(params[:id])
      @organizations = @user.organizations.order(:name)
      @notes = @user.notes.order(created_at: :desc).limit(10)
      @organization_memberships = @user.organization_memberships
        .joins(:organization)
        .order("organizations.name" => :asc)
        .includes(:organization)
      @last_email_verification_date = @user.email_authorizations
        .where.not(verified_at: nil)
        .order(created_at: :desc).first&.verified_at || "Never"
    end

    def update
      @user = User.find(params[:id])
      manage_credits
      add_note if user_params[:new_note]
      redirect_to "/admin/users/#{params[:id]}"
    end

    def user_status
      @user = User.find(params[:id])
      begin
        Moderator::ManageActivityAndRoles.handle_user_roles(admin: current_user, user: @user, user_params: user_params)
        flash[:success] = "User has been updated"
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to "/admin/users/#{@user.id}/edit"
    end

    def banish
      Moderator::BanishUserWorker.perform_async(current_user.id, params[:id].to_i)
      flash[:success] = "This user is being banished in the background. The job will complete soon."
      redirect_to "/admin/users/#{params[:id]}/edit"
    end

    def full_delete
      @user = User.find(params[:id])
      begin
        Moderator::DeleteUser.call(admin: current_user, user: @user, user_params: user_params)
        message = "@#{@user.username} (email: #{@user.email.presence || 'no email'}, user_id: #{@user.id}) " \
          "has been fully deleted. If requested, old content may have been ghostified. " \
          "If this is a GDPR delete, delete them from Mailchimp & Google Analytics."
        flash[:success] = message
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to "/admin/users"
    end

    def merge
      @user = User.find(params[:id])
      begin
        Moderator::MergeUser.call(admin: current_user, keep_user: @user, delete_user_id: user_params["merge_user_id"])
      rescue StandardError => e
        flash[:danger] = e.message
      end

      redirect_to "/admin/users/#{@user.id}/edit"
    end

    def remove_identity
      identity = Identity.find(user_params[:identity_id])
      @user = identity.user
      begin
        BackupData.backup!(identity)
        identity.delete
        @user.update("#{identity.provider}_username" => nil)
        flash[:success] = "The #{identity.provider.capitalize} identity was successfully deleted and backed up."
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to "/admin/users/#{@user.id}/edit"
    end

    def recover_identity
      backup = BackupData.find(user_params[:backup_data_id])
      @user = backup.instance_user
      begin
        identity = backup.recover!
        flash[:success] = "The #{identity.provider} identity was successfully recovered, and the backup was removed."
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to "/admin/users/#{@user.id}/edit"
    end

    def send_email
      if NotifyMailer.with(params).user_contact_email.deliver_now
        redirect_back(fallback_location: users_path)
      else
        flash[:danger] = "Email failed to send!"
      end
    end

    def verify_email_ownership
      if VerificationMailer.with(user_id: params[:user_id]).account_ownership_verification_email.deliver_now
        flash[:success] = "Email Verification Mailer sent!"
        redirect_back(fallback_location: admin_users_path)
      else
        flash[:danger] = "Email failed to send!"
      end
    end

    def unlock_access
      @user = User.find(params[:id])
      @user.unlock_access!
      flash[:success] = "Unlocked User account!"
      redirect_to admin_user_path(@user)
    end

    private

    def manage_credits
      add_credits if user_params[:add_credits]
      add_org_credits if user_params[:add_org_credits]
      remove_org_credits if user_params[:remove_org_credits]
      remove_credits if user_params[:remove_credits]
    end

    def add_note
      Note.create(
        author_id: current_user.id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: "misc_note",
        content: user_params[:new_note],
      )
    end

    def add_credits
      amount = user_params[:add_credits].to_i
      Credit.add_to(@user, amount)
    end

    def remove_credits
      amount = user_params[:remove_credits].to_i
      Credit.remove_from(@user, amount)
    end

    def add_org_credits
      org = Organization.find(user_params[:organization_id])
      amount = user_params[:add_org_credits].to_i
      Credit.add_to(org, amount)
    end

    def remove_org_credits
      org = Organization.find(user_params[:organization_id])
      amount = user_params[:remove_org_credits].to_i
      Credit.remove_from(org, amount)
    end

    def user_params
      allowed_params = %i[
        new_note note_for_current_role user_status
        pro merge_user_id add_credits remove_credits
        add_org_credits remove_org_credits ghostify
        organization_id identity_id backup_data_id
      ]
      params.require(:user).permit(allowed_params)
    end
  end
end
