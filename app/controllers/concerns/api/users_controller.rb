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
      set_surrogate_key_header(*@user.profile_cache_keys)

      if (json_body = serialize_user_natively(@user, joined_attributes: true))
        render json: json_body
        return
      end

      hydrate_joined_profile_and_setting(@user)
    end

    def me
      if (json_body = serialize_user_natively(
        @user,
        joined_attributes: false,
        include_followers_count: extended_user_payload?,
      ))
        render json: json_body
      end
    end

    # Finds a user by email and renders the show representation with joined associations hydrated.
    def search
      authorize(User, :search_by_email?)

      not_found unless params[:email]

      @user = serialized_users_relation.find_by(email: params[:email])

      if @user
        if (json_body = serialize_user_natively(@user, joined_attributes: true))
          render json: json_body
          return
        end

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

    def extended_user_payload?
      is_a?(Api::V1::UsersController)
    end

    def native_user_serialization_supported?
      ForemNative.available? &&
        ActiveSupport::JSON::Encoding.escape_html_entities_in_json &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?) &&
        I18n.locale == :en &&
        Time.zone&.tzinfo&.name == "Etc/UTC" &&
        Profile.static_fields == Profile::STATIC_FIELDS
    end

    def serialize_user_natively(user, joined_attributes:, include_followers_count: false)
      return unless native_user_serialization_supported?

      created_at = user.created_at
      return unless created_at.respond_to?(:tv_sec) && created_at.utc_offset.zero?

      if joined_attributes
        summary = user[:summary]
        location = user[:location]
        website_url = user[:website_url]
      else
        profile = user.profile
        return unless profile

        summary = profile.summary
        location = profile.location
        website_url = profile.website_url
      end

      user_fields = [
        user.id,
        user.username,
        user.name,
        user.twitter_username,
        user.github_username,
        summary,
        location,
        website_url,
        created_at.tv_sec,
        user.profile_image_url_for(length: 320),
      ]

      if extended_user_payload?
        ForemNative.serialize_api_user_json(
          user_fields,
          extended: true,
          email: extended_user_email(user, joined_attributes: joined_attributes),
          badge_ids: user.badge_ids,
          followers_count: include_followers_count ? user.good_standing_followers_count : nil,
        )
      else
        ForemNative.serialize_api_user_json(user_fields, extended: false)
      end
    end

    def extended_user_email(user, joined_attributes:)
      auth_user = authenticated_user
      return user.email if user == auth_user
      return if auth_user.blank?

      display_email = joined_attributes ? user[:display_email_on_profile] : user.setting.display_email_on_profile
      display_email ? user.email : nil
    end

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
