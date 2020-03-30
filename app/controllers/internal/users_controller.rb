class Internal::UsersController < Internal::ApplicationController
  layout "internal"

  after_action only: %i[update user_status banish full_delete merge] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

  def index
    @users = case params[:state]
             when /role\-/
               User.with_role(params[:state].split("-")[1], :any).page(params[:page]).per(50)
             else
               User.order("created_at DESC").page(params[:page]).per(50)
             end
    return if params[:search].blank?

    @users = @users.where('users.name ILIKE :search OR
      users.username ILIKE :search OR
      users.github_username ILIKE :search OR
      users.email ILIKE :search OR
      users.twitter_username ILIKE :search', search: "%#{params[:search].strip}%")
  end

  def edit
    @user = User.find(params[:id])
  end

  def show
    @user = User.find(params[:id])
    @organizations = @user.organizations
  end

  def update
    @user = User.find(params[:id])
    manage_credits
    add_note if user_params[:new_note]
    redirect_to "/internal/users/#{params[:id]}"
  end

  def user_status
    @user = User.find(params[:id])
    begin
      Moderator::ManageActivityAndRoles.handle_user_roles(admin: current_user, user: @user, user_params: user_params)
      flash[:success] = "User has been updated"
    rescue StandardError => e
      flash[:danger] = e.message
    end
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def banish
    Moderator::BanishUserWorker.perform_async(current_user.id, params[:id].to_i)
    flash[:success] = "This user is being banished in the background. The job will complete soon."
    redirect_to "/internal/users/#{params[:id]}/edit"
  end

  def full_delete
    @user = User.find(params[:id])
    begin
      Moderator::DeleteUser.call(admin: current_user, user: @user, user_params: user_params)
      flash[:success] = "@#{@user.username} (email: #{@user.email.presence || 'no email'}, user_id: #{@user.id}) has been fully deleted. If requested, old content may have been ghostified. If this is a GDPR delete, delete them from Mailchimp & Google Analytics."
    rescue StandardError => e
      flash[:danger] = e.message
    end
    redirect_to "/internal/users"
  end

  def merge
    @user = User.find(params[:id])
    begin
      Moderator::MergeUser.call_merge(admin: current_user, keep_user: @user, delete_user_id: user_params["merge_user_id"])
    rescue StandardError => e
      flash[:danger] = e.message
    end

    redirect_to "/internal/users/#{@user.id}/edit"
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
    redirect_to "/internal/users/#{@user.id}/edit"
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
    redirect_to "/internal/users/#{@user.id}/edit"
  end

  def send_email
    if NotifyMailer.user_contact_email(params).deliver
      redirect_back(fallback_location: "/users")
    else
      flash[:danger] = "Email failed to send!"
    end
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
    Credit.add_to_org(org, amount)
  end

  def remove_org_credits
    org = Organization.find(user_params[:organization_id])
    amount = user_params[:remove_org_credits].to_i
    Credit.remove_from_org(org, amount)
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
