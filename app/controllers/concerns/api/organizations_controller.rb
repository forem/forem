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

    LISTINGS_FOR_SERIALIZATION = %i[
      id user_id organization_id title slug body_markdown cached_tag_list
      classified_listing_category_id processed_html published created_at
    ].freeze
    private_constant :LISTINGS_FOR_SERIALIZATION

    ARTICLES_FOR_SERIALIZATION = Api::V0::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION

    def show
      @organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find_by!(username: params[:id_or_slug])
    end

    def users
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      @users = @organization.users.joins(:profile).select(USERS_FOR_SERIALIZATION).page(page).per(num)
    end

    def listings
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, per_page_max].min
      page = params[:page] || 1

      @listings = @organization.listings.published
        .select(LISTINGS_FOR_SERIALIZATION).page(page).per(num)
        .includes(:user, :taggings, :listing_category)
        .order(bumped_at: :desc)

      @listings = @listings.in_category(params[:category]) if params[:category].present?
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
