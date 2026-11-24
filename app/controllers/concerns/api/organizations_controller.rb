module Api
  module OrganizationsController
    extend ActiveSupport::Concern

    SHOW_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id username name summary twitter_username github_username url
      location created_at profile_image tech_stack tag_line story
    ].freeze
    private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

    USERS_FOR_SERIALIZATION = %i[
      id username name twitter_username github_username
      profile_image website_url location summary created_at
    ].freeze
    private_constant :USERS_FOR_SERIALIZATION

    ARTICLES_FOR_SERIALIZATION = Api::V0::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION

    def show
      @organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find_by!(username: params[:id_or_slug])

      render_organization_show_json(@organization)
    end

    def users
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      @users = @organization.users.joins(:profile).select(USERS_FOR_SERIALIZATION).page(page).per(num)

      if (json_body = serialize_organization_users_natively(@users))
        render json: json_body
        return
      end

      @users.each { |user| hydrate_joined_profile(user) }
    end

    # Listings were removed (#21795) and the Listing model no longer defines
    # scopes or associations; mirror Api::ListingsController#index.
    def listings
      render json: []
    end

    def articles
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      @articles = @organization.articles.published.from_subforem
        .select(ARTICLES_FOR_SERIALIZATION)
        .includes(:user)
        .order(published_at: :desc)
        .page(page)
        .per(num)
        .decorate

      render "api/v0/articles/index", formats: :json
    end

    private

    def native_api_json_format?
      ForemNative.available? &&
        ActiveSupport::JSON::Encoding.escape_html_entities_in_json &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?)
    end

    def native_users_serialization_supported?
      native_api_json_format? &&
        I18n.locale == :en &&
        Time.zone&.tzinfo&.name == "Etc/UTC" &&
        Profile.static_fields == Profile::STATIC_FIELDS
    end

    def render_organization_show_json(organization)
      if (json_body = serialize_organization_natively(organization))
        render json: json_body
        return
      end

      render :show
    end

    def serialize_organization_natively(organization)
      return unless native_api_json_format?

      created_at = organization.created_at
      return if created_at && !created_at.respond_to?(:tv_sec)

      ForemNative.serialize_api_organization_json(
        [
          organization.id,
          organization.username,
          organization.name,
          organization.summary,
          organization.twitter_username,
          organization.github_username,
          organization.url,
          organization.location,
          organization.tech_stack,
          organization.tag_line,
          organization.story,
          created_at&.tv_sec,
          organization.profile_image_url_for(length: 640),
        ],
      )
    end

    def serialize_organization_users_natively(users)
      return unless native_users_serialization_supported?

      records = users.to_a
      return "[]" if records.empty?

      users_flat = Array.new(records.size * 10)
      idx = 0
      records.each do |user|
        created_at = user.created_at
        return nil unless created_at.respond_to?(:tv_sec) && created_at.utc_offset.zero?

        users_flat[idx] = user.id
        users_flat[idx + 1] = user.username
        users_flat[idx + 2] = user.name
        users_flat[idx + 3] = user.twitter_username
        users_flat[idx + 4] = user.github_username
        users_flat[idx + 5] = user[:summary]
        users_flat[idx + 6] = user[:location]
        users_flat[idx + 7] = user[:website_url]
        users_flat[idx + 8] = created_at.tv_sec
        users_flat[idx + 9] = user.profile_image_url_for(length: 320)
        idx += 10
      end

      ForemNative.serialize_api_users_json(users_flat)
    end

    def hydrate_joined_profile(user)
      profile = Profile.instantiate(
        "user_id" => user.id,
        "summary" => user[:summary],
        "location" => user[:location],
        "website_url" => user[:website_url],
      )
      profile.readonly!
      user.association(:profile).target = profile
    end

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end

    def find_organization
      # Looking up via id_or_slug parameter since both types of lookup are handled in
      # the v1 show route
      @organization = Organization.find_by(id: params[:organization_id_or_slug]) ||
        Organization.find_by(username: params[:organization_id_or_slug])
      raise ActiveRecord::RecordNotFound unless @organization
    end
  end
end
