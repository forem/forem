module Api
  module V0
    class OrganizationsController < ApiController
      before_action :find_organization, only: %i[users listings articles stats]
      before_action :authenticate!, only: %i[stats]
      before_action -> { doorkeeper_authorize! :public }, only: %w[show users listings articles], if: -> { doorkeeper_token }

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
        classified_listing_category_id processed_html published
      ].freeze
      private_constant :LISTINGS_FOR_SERIALIZATION

      STATS_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id user_id organization_id
        title description main_image published published_at cached_tag_list
        slug path canonical_url comments_count public_reactions_count
        page_views_count crossposted_at body_markdown updated_at
      ].freeze
      private_constant :STATS_ATTRIBUTES_FOR_SERIALIZATION

      ARTICLES_FOR_SERIALIZATION = Api::V0::ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION

      def show
        @organization = Organization.select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
          .find_by!(username: params[:username])
      end

      def users
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min
        page = params[:page] || 1

        @users = @organization.users.select(USERS_FOR_SERIALIZATION).page(page).per(num)
      end

      def listings
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min
        page = params[:page] || 1

        @listings = @organization.listings.published
          .select(LISTINGS_FOR_SERIALIZATION).page(page).per(num)
          .includes(:user, :taggings, :listing_category)
          .order(bumped_at: :desc)

        @listings = @listings.in_category(params[:category]) if params[:category].present?
      end

      def articles
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min
        page = params[:page] || 1

        @articles = @organization.articles.published
          .select(ARTICLES_FOR_SERIALIZATION)
          .includes(:user)
          .order(published_at: :desc)
          .page(page)
          .per(num)
          .decorate

        render "api/v0/articles/index.json.jbuilder"
      end

      def stats
        doorkeeper_scope = %w[unpublished all].include?(params[:status]) ? :read_articles : :public
        doorkeeper_authorize! doorkeeper_scope if doorkeeper_token

        per_page = (params[:per_page] || 30).to_i
        num = [per_page, 1000].min
        page = params[:page] || 1

        @articles = case params[:status]
                    when "published"
                      @user.articles.published
                    when "unpublished"
                      @user.articles.unpublished
                    when "all"
                      @user.articles
                    else
                      @user.articles.published
                    end

        @articles = @organization.articles.published
          .select(STATS_ATTRIBUTES_FOR_SERIALIZATION)
          .includes(:user)
          .order(published_at: :desc)
          .page(page)
          .per(num)
          .decorate
      end

      private

      def find_organization
        @organization = Organization.find_by!(username: params[:organization_username])
      end
    end
  end
end
