module Api
  module UsersController
    extend ActiveSupport::Concern

    SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id username name summary twitter_username github_username website_url
      location created_at profile_image registered
    ].freeze
    ATTRIBUTES_FOR_SELECT = (SHOW_ATTRIBUTES_FOR_SERIALIZATION + %i[display_email_on_profile email]).freeze
    private_constant :ATTRIBUTES_FOR_SELECT

    # Renders a registered user by ID or username with joined profile and setting fields hydrated.
    def show
      relation = serialized_users_relation

      @user = if params[:id] == "by_username"
                relation.find_by!(username: params[:url])
              else
                relation.find(params[:id])
              end
      not_found unless @user.registered
      hydrate_joined_profile_and_setting(@user)
      set_surrogate_key_header(*@user.profile_cache_keys)
    end

    def me; end

    # Finds a user by email and renders the show representation with joined associations hydrated.
    def search
      authorize(User, :search_by_email?)

      not_found unless params[:email]

      @user = serialized_users_relation.find_by(email: params[:email])

      if @user
        hydrate_joined_profile_and_setting(@user)
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

    private

    # Builds the relation joining profile and setting columns needed by user show serialization.
    def serialized_users_relation
      User.joins(:profile).joins(:setting).select(ATTRIBUTES_FOR_SELECT)
    end

    # Populates read-only profile and setting association targets from joined attributes on user.
    def hydrate_joined_profile_and_setting(user)
      profile = Profile.instantiate(
        "user_id" => user.id,
        "summary" => user[:summary],
        "location" => user[:location],
        "website_url" => user[:website_url],
      )
      profile.readonly!
      user.association(:profile).target = profile

      setting = Users::Setting.instantiate(
        "user_id" => user.id,
        "display_email_on_profile" => user[:display_email_on_profile],
      )
      setting.readonly!
      user.association(:setting).target = setting
    end
  end
end
