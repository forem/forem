module Admin
  class UsersController < Admin::ApplicationController
    layout "admin"
    using StringToBoolean

    USER_ALLOWED_PARAMS = %i[
      new_note note_for_current_role user_status
      merge_user_id add_credits remove_credits
      add_org_credits remove_org_credits
      organization_id identity_id
      credit_action credit_amount
    ].freeze

    EMAIL_ALLOWED_PARAMS = %i[
      email_subject
      email_body
    ].freeze

    after_action only: %i[update user_status banish full_delete unpublish_all_articles merge] do
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

      if FeatureFlag.enabled?(:admin_member_view)
        set_current_tab(params[:tab])
        set_feedback_messages
        set_related_reactions
      end
      set_user_details
    end

    def update
      @user = User.find(params[:id])

      Credits::Manage.call(@user, credit_params)
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
      redirect_to admin_user_path(params[:id])
    end

    def user_status
      @user = User.find(params[:id])
      begin
        Moderator::ManageActivityAndRoles.handle_user_roles(admin: current_user, user: @user, user_params: user_params)
        flash[:success] = "User has been updated"
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to admin_user_path(params[:id])
    end

    def export_data
      user = User.find(params[:id])
      send_to_admin = params[:send_to_admin].to_boolean
      if send_to_admin
        email = ::ForemInstance.contact_email
        receiver = "admin"
      else
        email = user.email
        receiver = "user"
      end
      ExportContentWorker.perform_async(user.id, email)
      flash[:success] = "Data exported to the #{receiver}. The job will complete momentarily."
      redirect_to admin_user_path(params[:id])
    end

    def banish
      Moderator::BanishUserWorker.perform_async(current_user.id, params[:id].to_i)
      flash[:success] = "This user is being banished in the background. The job will complete soon."
      redirect_to admin_user_path(params[:id])
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

    def unpublish_all_articles
      Moderator::UnpublishAllArticlesWorker.perform_async(params[:id].to_i)
      flash[:success] = "Posts are being unpublished in the background. The job will complete soon."
      redirect_to admin_user_path(params[:id])
    end

    def merge
      @user = User.find(params[:id])
      begin
        Moderator::MergeUser.call(admin: current_user, keep_user: @user, delete_user_id: user_params["merge_user_id"])
      rescue StandardError => e
        flash[:danger] = e.message
      end

      redirect_to admin_user_path(params[:id])
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
      redirect_to admin_user_path(params[:id])
    end

    def send_email
      email_params = {
        email_body: send_email_params[:email_body],
        email_subject: send_email_params[:email_subject],
        user_id: params[:id]
      }

      if NotifyMailer.with(email_params).user_contact_email.deliver_now
        respond_to do |format|
          message = "Email sent!"

          format.html do
            flash[:success] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js { render json: { result: message }, content_type: "application/json" }
        end
      else
        respond_to do |format|
          message = "Email failed to send!"

          format.html do
            flash[:danger] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js do
            render json: { error: message },
                   content_type: "application/json",
                   status: :service_unavailable
          end
        end
      end
    rescue ActionController::ParameterMissing
      respond_to do |format|
        format.json do
          render json: { error: "Both subject and body are required!" },
                 content_type: "application/json",
                 status: :unprocessable_entity
        end
      end
    end

    def verify_email_ownership
      if VerificationMailer.with(user_id: params[:id]).account_ownership_verification_email.deliver_now
        respond_to do |format|
          message = "Verification email sent!"

          format.html do
            flash[:success] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js { render json: { result: message }, content_type: "application/json" }
        end
      else
        message = "Email failed to send!"

        respond_to do |format|
          format.html do
            flash[:danger] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js { render json: { error: message }, content_type: "application/json", status: :service_unavailable }
        end
      end
    end

    def unlock_access
      @user = User.find(params[:id])
      @user.unlock_access!
      flash[:success] = "Unlocked User account!"
      redirect_to admin_user_path(@user)
    end

    private

    def set_user_details
      @organizations = @user.organizations.order(:name)
      @notes = @user.notes.order(created_at: :desc).limit(10)
      @organization_memberships = @user.organization_memberships
        .joins(:organization)
        .order("organizations.name" => :asc)
        .includes(:organization)
      @last_email_verification_date = EmailAuthorization.last_verification_date(@user)

      render :show
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

    def set_feedback_messages
      @related_reports = FeedbackMessage.where(id: @user.reporter_feedback_messages.ids)
        .or(FeedbackMessage.where(id: @user.affected_feedback_messages.ids))
        .or(FeedbackMessage.where(id: @user.offender_feedback_messages.ids))
        .order(created_at: :desc).limit(15)
    end

    def set_related_reactions
      user_article_ids = @user.articles.ids
      user_comment_ids = @user.comments.ids
      @related_vomit_reactions =
        Reaction.where(reactable_type: "Comment", reactable_id: user_comment_ids, category: "vomit")
          .or(Reaction.where(reactable_type: "Article", reactable_id: user_article_ids, category: "vomit"))
          .or(Reaction.where(reactable_type: "User", reactable_id: @user.id, category: "vomit"))
          .includes(:reactable)
          .order(created_at: :desc).limit(15)
    end

    def user_params
      params.require(:user).permit(USER_ALLOWED_PARAMS)
    end

    def send_email_params
      params.require(EMAIL_ALLOWED_PARAMS)
      params.permit(EMAIL_ALLOWED_PARAMS)
    end

    def credit_params
      return user_params unless FeatureFlag.enabled?(:admin_member_view)

      credit_params = {}
      if user_params[:credit_action] == "Add"
        credit_params[:add_credits] = user_params[:credit_amount]
        flash[:success] = "Credits have been added!"
      end

      if user_params[:credit_action] == "Remove"
        credit_params[:remove_credits] = user_params[:credit_amount]
        flash[:success] = "Credits have been removed."
      end

      credit_params
    end

    def set_current_tab(current_tab = "overview")
      @current_tab = if current_tab.in? Constants::UserDetails::TAB_LIST.map(&:downcase)
                       current_tab
                     else
                       "overview"
                     end
    end
  end
end
