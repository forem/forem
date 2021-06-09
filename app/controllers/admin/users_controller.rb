module Admin
  class UsersController < Admin::ApplicationController
    layout "admin"
    using StringToBoolean

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
      set_feedback_messages
      set_related_reactions
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
      Credits::Manage.call(@user, user_params)
      add_note if user_params[:new_note]
      redirect_to admin_user_path(params[:id])
    end

    def destroy
      role = params[:role].to_sym
      resource_type = params[:resource_type]

      @user = User.find(params[:user_id])

      response = ::Users::RemoveRole.call(user: @user,
                                          role: role,
                                          resource_type: resource_type,
                                          admin: current_user)
      if response.success
        flash[:success] = "Role: #{role.to_s.humanize.titlecase} has been successfully removed from the user!"
      else
        flash[:danger] = response.error_message
      end
      redirect_to edit_admin_user_path(@user.id)
    end

    def user_status
      @user = User.find(params[:id])
      begin
        Moderator::ManageActivityAndRoles.handle_user_roles(admin: current_user, user: @user, user_params: user_params)
        flash[:success] = "User has been updated"
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to edit_admin_user_path(@user.id)
    end

    def export_data
      user = User.find(params[:id])
      send_to_admin = params[:send_to_admin].to_boolean
      if send_to_admin
        email = ::Settings::General.email_addresses[:default]
        receiver = "admin"
      else
        email = user.email
        receiver = "user"
      end
      ExportContentWorker.perform_async(user.id, email)
      flash[:success] = "Data exported to the #{receiver}. The job will complete momentarily."
      redirect_to edit_admin_user_path(user.id)
    end

    def banish
      Moderator::BanishUserWorker.perform_async(current_user.id, params[:id].to_i)
      flash[:success] = "This user is being banished in the background. The job will complete soon."
      redirect_to edit_admin_user_path(params[:id])
    end

    def full_delete
      @user = User.find(params[:id])
      begin
        Moderator::DeleteUser.call(user: @user)
        link = helpers.tag.a("the page", href: admin_users_gdpr_delete_requests_path, data: { "no-instant" => true })
        message = "@#{@user.username} (email: #{@user.email.presence || 'no email'}, user_id: #{@user.id}) " \
          "has been fully deleted. " \
          "If this is a GDPR delete, delete them from Mailchimp & Google Analytics " \
          " and confirm on "
        flash[:success] = helpers.safe_join([message, link, "."])
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to admin_users_path
    end

    def merge
      @user = User.find(params[:id])
      begin
        Moderator::MergeUser.call(admin: current_user, keep_user: @user, delete_user_id: user_params["merge_user_id"])
      rescue StandardError => e
        flash[:danger] = e.message
      end

      redirect_to edit_admin_user_path(@user.id)
    end

    def remove_identity
      identity = Identity.find(user_params[:identity_id])
      @user = identity.user

      begin
        identity.destroy

        @user.update("#{identity.provider}_username" => nil)

        # GitHub repositories are tied with the existence of the GitHub identity
        # as we use the user's GitHub token to fetch them from the API.
        # We should delete them when a user unlinks their GitHub account.
        @user.github_repos.destroy_all if identity.provider.to_sym == :github

        flash[:success] = "The #{identity.provider.capitalize} identity was successfully deleted and backed up."
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to edit_admin_user_path(@user.id)
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

    def add_note
      Note.create(
        author_id: current_user.id,
        noteable_id: @user.id,
        noteable_type: "User",
        reason: "misc_note",
        content: user_params[:new_note],
      )
    end

    def set_feedback_messages
      @related_reports = FeedbackMessage.where(id: @user.reporter_feedback_messages.ids)
        .or(FeedbackMessage.where(id: @user.affected_feedback_messages.ids))
        .or(FeedbackMessage.where(id: @user.offender_feedback_messages.ids))
        .order(created_at: :desc).limit(15)
    end

    def set_related_reactions
      user_article_ids = @user.articles.ids
      user_comment_ids = @user.comments.ids
      @related_vomit_reactions = Reaction.where(reactable_type: "Comment", reactable_id: user_comment_ids,
                                                category: "vomit")
        .or(Reaction.where(reactable_type: "Article", reactable_id: user_article_ids, category: "vomit"))
        .or(Reaction.where(reactable_type: "User", user_id: @user.id, category: "vomit"))
        .includes(:reactable)
        .order(created_at: :desc).limit(15)
    end

    def user_params
      allowed_params = %i[
        new_note note_for_current_role user_status
        merge_user_id add_credits remove_credits
        add_org_credits remove_org_credits
        organization_id identity_id
      ]
      params.require(:user).permit(allowed_params)
    end
  end
end
