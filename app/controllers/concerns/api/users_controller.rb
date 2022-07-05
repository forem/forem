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
      target_user = User.find(params[:id])
      suspend_params = { note_for_current_role: params[:note], user_status: "Suspended" }

      begin
        Moderator::ManageActivityAndRoles.handle_user_roles(admin: @user, user: target_user,
                                                            user_params: suspend_params)
        Note.create(
          author_id: @user.id,
          noteable_id: target_user.id,
          noteable_type: "User",
          reason: "misc_note",
          content: params[:note],
        )
        render json: { message: "success" }
      rescue StandardError
        render json: {
          success: false,
          message: @user.errors_as_sentence
        }, status: :unprocessable_entity
      end
    end
  end
end
