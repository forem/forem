module Api
  module UsersController
    extend ActiveSupport::Concern

    SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id username name summary twitter_username github_username website_url
      location created_at profile_image registered
    ].freeze

    def show
      attributes_for_select = SHOW_ATTRIBUTES_FOR_SERIALIZATION + %i[display_email_on_profile email]
      relation = User.joins(:profile).joins(:setting).select(attributes_for_select)

      @user = if params[:id] == "by_username"
                relation.find_by!(username: params[:url])
              else
                relation.find(params[:id])
              end
      not_found unless @user.registered
    end

    def me; end

    def search
      authorize(User, :search_by_email?)

      not_found unless params[:email]

      @user = User.find_by(email: params[:email])

      if @user
        render :show
      else
        not_found
      end
    end

    def unpublish
      authorize(@user, :unpublish_all_articles?)

      target_user = User.find(params[:id].to_i)

      Moderator::UnpublishAllArticlesWorker.perform_async(target_user.id, @user.id)

      note_content = params[:note].presence || "#{@user.username} requested unpublish all articles via API"

      Note.create(noteable: target_user, reason: "unpublish_all_articles",
                  content: note_content, author: @user)

      render status: :no_content
    end
  end
end
