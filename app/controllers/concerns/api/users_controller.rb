module Api
  module UsersController
    extend ActiveSupport::Concern

    SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id username name summary twitter_username github_username website_url
      location created_at profile_image registered
    ].freeze

    def show
      relation = User.joins(:profile).select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)

      @user = if params[:id] == "by_username"
                relation.find_by!(username: params[:url])
              else
                relation.find(params[:id])
              end
      not_found unless @user.registered
    end

    def me
      render :show
    end

    def suspend
      authorize(@user, :toggle_suspension_status?)

      target_user = User.find(params[:id])
      suspend_params = { note_for_current_role: params[:note], user_status: "Suspended" }

      begin
        Moderator::ManageActivityAndRoles.handle_user_roles(admin: @user,
                                                            user: target_user,
                                                            user_params: suspend_params)

        payload = { action: "api_user_suspend", target_user_id: target_user.id }
        Audit::Logger.log(:admin_api, @user, payload)

        render head: :ok
      rescue StandardError
        render json: {
          success: false,
          message: @user.errors_as_sentence
        }, status: :unprocessable_entity
      end
    end

    def unpublish
      authorize(@user, :unpublish_all_articles?)

      target_user = User.find(params[:id].to_i)
      target_articles = Article.published.where(user_id: target_user.id)
      Moderator::UnpublishAllArticlesWorker.perform_async(target_user.id)

      target_comments = target_user.comments.where(deleted: false)
      # Keep track of the ids that will be affected for the AuditLog later
      target_comment_ids = target_comments.ids
      target_comments.update(deleted: true)

      payload = {
        action: "api_user_unpublish",
        target_user_id: target_user.id,
        target_article_ids: target_articles.ids,
        target_comment_ids: target_comment_ids
      }
      Audit::Logger.log(:admin_api, @user, payload)

      render head: :ok
    end
  end
end
