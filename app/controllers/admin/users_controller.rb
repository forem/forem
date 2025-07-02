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
      reputation_modifier
      max_score
      tag_name
      email
    ].freeze

    EMAIL_ALLOWED_PARAMS = %i[
      email_subject
      email_body
    ].freeze

    ATTRIBUTES_FOR_CSV = %i[
      id name username email registered_at
    ].freeze

    ATTRIBUTES_FOR_LAST_ACTIVITY = %i[
      registered last_comment_at last_article_at latest_article_updated_at last_reacted_at profile_updated_at
      last_moderation_notification last_notification_activity
    ].freeze

    MODROLE_ACTIONS_TO_POLICIES = {
      user_status: :toggle_suspension_status?,
      unpublish_all_articles: :unpublish_all_articles?
    }.freeze

    after_action only: %i[update user_status banish full_delete merge] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    # Having this method here (which also exists in admin/application_controller)
    # allows us to authorize the actions of the moderator role specifically,
    # while preserving the implementation for all other admin actions
    def authorize_admin
      if MODROLE_ACTIONS_TO_POLICIES.key?(action_name.to_sym)
        authorize(User, MODROLE_ACTIONS_TO_POLICIES[action_name.to_sym])
      else
        super
      end
    end

    def index
      respond_to do |format|
        format.html { index_for_html }
        format.json { index_for_json }
      end
    end

    def show
      @user = User.find(params[:id])
      set_current_tab(params[:tab])
      set_unpublish_all_log
      set_banishable_user
      set_feedback_messages
      set_related_reactions
      @articles = @user.articles.order(created_at: :desc)
      # Remove the .includes(:commentable)
      @comments = @user.comments.order(created_at: :desc)
      set_user_details
    end

    def edit
      @user = User.find(params[:id])
      @notes = @user.notes.order(created_at: :desc).limit(10).load
      set_feedback_messages
      set_related_reactions
    end

    def update
      @user = User.find(params[:id])

      Credits::Manage.call(@user, credit_params)
      add_note if user_params[:new_note]

      redirect_to admin_user_path(params[:id])
    end

    def reputation_modifier
      @user = User.find(params[:id])
      reputation_modifier_value = user_params[:reputation_modifier]
      note_content = if user_params[:new_note].present?
                       "Changed user's reputation modifier to #{reputation_modifier_value}. " \
                         "Reason: #{user_params[:new_note]}"
                     else
                       "Changed user's reputation modifier to #{reputation_modifier_value}."
                     end
      if @user.update(reputation_modifier: reputation_modifier_value)
        Note.create(
          author_id: current_user.id,
          noteable_id: @user.id,
          noteable_type: "User",
          reason: "reputation_modifier_change",
          content: note_content,
        )
        flash[:success] = I18n.t("views.admin.users.reputation.success", reputation_modifier: reputation_modifier_value)
      else
        flash[:error] = I18n.t("views.admin.users.reputation.error")
      end
      redirect_to admin_user_path(@user)
    end

    def update_email
      @user = User.find(params[:id])
      old_email = @user.email
      new_email = user_params[:email]
      if @user.update_columns(email: new_email)
        Note.create(
          author_id: current_user.id,
          noteable_id: @user.id,
          noteable_type: "User",
          reason: "Update Email",
          content: "Updated email from #{old_email} to #{new_email}",
        )
        flash[:success] = I18n.t("views.admin.users.update_email.success")
      else
        flash[:error] = I18n.t("views.admin.users.update_email.error")
      end
      redirect_to admin_user_path(@user)
    end

    def max_score
      @user = User.find(params[:id])
      max_score_value = user_params[:max_score]
      note_content = if user_params[:new_note].present?
                       "Changed user's maximum score to #{max_score_value}. " \
                         "Reason: #{user_params[:new_note]}"
                     else
                       "Changed user's maximum score to #{max_score_value}."
                     end
      if @user.update(max_score: max_score_value)
        Note.create(
          author_id: current_user.id,
          noteable_id: @user.id,
          noteable_type: "User",
          reason: "max_score_change",
          content: note_content,
        )
        flash[:success] = I18n.t("views.admin.users.max_score.success", max_score: max_score_value)
      else
        flash[:error] = I18n.t("views.admin.users.max_score.error")
      end
      redirect_to admin_user_path(@user)
    end

    def destroy
      role = Role.find(params[:role_id])
      authorize(role, :remove_role?)

      @user = User.find(params[:user_id])

      response = ::Users::RemoveRole.call(
        user: @user,
        role: role.name,
        resource_type: params[:resource_type],
        resource_id: params[:resource_id],
      )

      if response.success
        flash[:success] =
          I18n.t("admin.users_controller.role_removed",
                 role: I18n.t("views.admin.users.overview.roles.name.#{
                   role.name_labelize.underscore.parameterize(separator: '_')
                 }", default: role.name.to_s.humanize.titlecase)) # TODO: [@yheuhtozr] need better role i18n
      else
        flash[:danger] = response.error_message
      end
      redirect_to admin_user_path(params[:id])
    end

    def export
      @users = User.registered.select(ATTRIBUTES_FOR_CSV + ATTRIBUTES_FOR_LAST_ACTIVITY).includes(:organizations)

      respond_to do |format|
        format.csv do
          response.headers["Content-Type"] = "text/csv"
          response.headers["Content-Disposition"] = "attachment; filename=users.csv"
          render template: "admin/users/export"
        end
      end
    end

    def user_status
      @user = User.find(params[:id])
      begin
        Moderator::ManageActivityAndRoles.handle_user_roles(admin: current_user, user: @user, user_params: user_params)
        flash[:success] = I18n.t("admin.users_controller.updated")
        respond_to do |format|
          format.html do
            redirect_back_or_to admin_users_path
          end
          format.json do
            render json: {
              success: true,
              message: I18n.t("admin.users_controller.updated_json", username: @user.username)
            }, status: :ok
          end
        end
      rescue StandardError => e
        flash[:danger] = e.message
        respond_to do |format|
          format.html do
            redirect_back_or_to admin_users_path
          end
          format.json do
            render json: {
              success: false,
              message: @user.errors_as_sentence
            }, status: :unprocessable_entity
          end
        end
      end
      Credits::Manage.call(@user, credit_params)
    end

    def add_tag_mod_role
      user = User.find(params[:id])
      tag = Tag.find_by(name: user_params[:tag_name])

      unless tag
        flash[:error] = I18n.t("errors.messages.general",
                               errors: I18n.t("admin.users_controller.tag_not_found",
                                              tag_name: user_params[:tag_name]))
        return redirect_to admin_user_path(user.id)
      end

      result = TagModerators::Add.call(user.id, tag.id)
      if result.success?
        flash[:success] = I18n.t("admin.tags.moderators_controller.added", username: user.username)
      else
        flash[:error] = I18n.t("errors.messages.general", errors:
          I18n.t("admin.tags.moderators_controller.not_found_or",
                 user_id: user.id,
                 errors: result.errors))
      end
      redirect_to admin_user_path(user.id)
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
      flash[:success] = I18n.t("admin.users_controller.exported", receiver: receiver)
      redirect_to admin_user_path(params[:id])
    end

    def banish
      Moderator::BanishUserWorker.perform_async(current_user.id, params[:id].to_i)
      flash[:success] = I18n.t("admin.users_controller.banished")
      redirect_to admin_user_path(params[:id])
    end

    def full_delete
      @user = User.find(params[:id])
      begin
        Moderator::DeleteUser.call(user: @user)
        link = helpers.tag.a(I18n.t("admin.users_controller.the_page"), href: admin_gdpr_delete_requests_path,
                                                                        data: { "no-instant" => true })
        flash[:success] = I18n.t("admin.users_controller.full_delete_html",
                                 user: @user.username,
                                 email: @user.email.presence || I18n.t("admin.users_controller.no_email"),
                                 id: @user.id,
                                 the_page: link).html_safe
      rescue StandardError => e
        flash[:danger] = e.message
      end
      redirect_to admin_users_path
    end

    def unpublish_all_articles
      target_user = User.find(params[:id].to_i)
      Moderator::UnpublishAllArticlesWorker.perform_async(target_user.id, current_user.id, "moderator")

      note_content = params.dig(:note, :content).presence
      note_content ||= "#{current_user.username} unpublished all articles"
      Note.create(noteable: target_user, reason: "unpublish_all_articles",
                  content: note_content, author: current_user)

      message = I18n.t("admin.users_controller.unpublished")
      respond_to do |format|
        format.html do
          flash[:success] = message
          redirect_to admin_user_path(params[:id])
        end

        format.json do
          render json: { message: message }
        end
      end
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

        flash[:success] =
          I18n.t("admin.users_controller.identity_removed",
                 provider: identity.provider.capitalize)
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
          message = I18n.t("admin.users_controller.email_sent")

          format.html do
            flash[:success] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js { render json: { result: message }, content_type: "application/json" }
        end
      else
        respond_to do |format|
          message = I18n.t("admin.users_controller.email_fail")

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
          render json: { error: I18n.t("admin.users_controller.parameter_missing") },
                 content_type: "application/json",
                 status: :unprocessable_entity
        end
      end
    end

    def send_email_confirmation
      @user = User.find(params[:id])
      if @user.send_confirmation_instructions
        respond_to do |format|
          message = I18n.t("admin.users_controller.confirm_sent")

          format.html do
            flash[:success] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js { render json: { result: message }, content_type: "application/json" }
        end
      else
        message = I18n.t("admin.users_controller.email_fail")

        respond_to do |format|
          format.html do
            flash[:danger] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js { render json: { error: message }, content_type: "application/json", status: :service_unavailable }
        end
      end
    end

    def verify_email_ownership
      if VerificationMailer.with(user_id: params[:id]).account_ownership_verification_email.deliver_now
        respond_to do |format|
          message = I18n.t("admin.users_controller.verify_sent")

          format.html do
            flash[:success] = message
            redirect_back(fallback_location: admin_user_path(params[:id]))
          end

          format.js { render json: { result: message }, content_type: "application/json" }
        end
      else
        message = I18n.t("admin.users_controller.email_fail")

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
      flash[:success] = I18n.t("admin.users_controller.unlocked")
      redirect_to admin_user_path(@user)
    end

    private

    def index_for_html
      @users = Admin::UsersQuery.call(
        relation: User.registered,
        search: params[:search],
        role: params[:role],
        roles: params[:roles],
        statuses: params[:statuses],
        joining_start: params[:joining_start],
        joining_end: params[:joining_end],
        date_format: params[:date_format],
        organizations: params[:organizations],
      ).page(params[:page]).per(50)

      @organization_limit = 3
      @organizations = Organization.order(name: :desc)
      @earliest_join_date = User.first.registered_at.to_s
    end

    def index_for_json
      @users = Admin::UsersQuery.call(
        relation: User.registered,
        search: params[:search],
        ids: params[:ids],
        limit: params[:limit],
      )

      render json: @users.to_json(only: %i[id name username])
    end

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
          .includes(:user)
          .order(created_at: :desc).limit(15)

      @user_vomit_reactions =
        Reaction.where(reactable_type: "User", reactable_id: @user.id, category: "vomit")
          .includes(:user)
          .order(created_at: :desc)
      @countable_flags = calculate_countable_flags(@user_vomit_reactions)
    end

    def user_params
      params.require(:user).permit(USER_ALLOWED_PARAMS)
    end

    def send_email_params
      params.require(EMAIL_ALLOWED_PARAMS)
      params.permit(EMAIL_ALLOWED_PARAMS)
    end

    def credit_params
      credit_params = {}

      case user_params[:credit_action]
      when "Add"
        credit_params[:add_credits] = user_params[:credit_amount]
        flash[:success] = I18n.t("admin.users_controller.credits_added")
      when "Remove"
        credit_params[:remove_credits] = user_params[:credit_amount]
        flash[:success] = I18n.t("admin.users_controller.credits_removed")
      else
        return user_params
      end
      credit_params
    end

    def set_current_tab(current_tab = "overview")
      @current_tab = if current_tab.in? Constants::UserDetails::TAB_LIST.map(&:underscore)
                       current_tab
                     else
                       "overview"
                     end
    end

    def set_banishable_user
      @banishable_user = (@user.comments.where("created_at < ?", 100.days.ago).empty? &&
        @user.created_at < 100.days.ago) || current_user.super_admin? || current_user.support_admin?
    end

    def set_unpublish_all_log
      # in theory, there could be multiple "unpublish all" actions
      # but let's query and display the last one for now, that should be enough for most cases
      @unpublish_all_data = if @current_tab == "unpublish_logs"
                              AuditLog::UnpublishAllsQuery.call(@user.id)
                            else
                              # only find if the data exists for most tabs
                              AuditLog::UnpublishAllsQuery.new(@user.id).exists?
                            end
    end

    def calculate_countable_flags(reactions)
      countable_flags = 0
      reactions.each do |reaction|
        countable_flags += 1 if reaction.status != "invalid"
      end
      countable_flags
    end
  end
end
