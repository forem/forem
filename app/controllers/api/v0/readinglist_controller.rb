module Api
  module V0
    class ReadinglistController < ApiController
      before_action :authenticate!
      before_action -> { doorkeeper_authorize! :public }, only: %w[index], if: -> { doorkeeper_token }

      INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION = %i[id reactable_id created_at status].freeze
      private_constant :INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION

      INDEX_ARTICLES_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id user_id organization_id collection_id
        title description main_image published_at crossposted_at social_image
        cached_tag_list slug path canonical_url comments_count
        public_reactions_count created_at edited_at last_comment_at published
        updated_at video_thumbnail_url
      ].freeze
      private_constant :INDEX_ARTICLES_ATTRIBUTES_FOR_SERIALIZATION

      INDEX_USERS_ATTRIBUTES_FOR_SERIALIZATION = %i[
        id username name summary twitter_username github_username website_url
        location created_at profile_image registered
      ].freeze
      private_constant :INDEX_USERS_ATTRIBUTES_FOR_SERIALIZATION

      PER_PAGE_MAX = 100
      private_constant :PER_PAGE_MAX

      def index
        per_page = (params[:per_page] || 30).to_i
        num = [per_page, PER_PAGE_MAX].min

        @readinglist = Reaction
          .select(INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION)
          .readinglist
          .where(user_id: @user.id)
          .where.not(status: "archived")
          .order(created_at: :desc)
          .page(params[:page])
          .per(num)

        articles = Article
          .includes(:organization)
          .select(INDEX_ARTICLES_ATTRIBUTES_FOR_SERIALIZATION)
          .where(id: @readinglist.map(&:reactable_id))
          .decorate

        @users_by_id = User
          .select(INDEX_USERS_ATTRIBUTES_FOR_SERIALIZATION)
          .find(articles.map(&:user_id))
          .index_by(&:id)

        articles_by_id = articles.index_by(&:id)

        @articles_by_reaction_ids = @readinglist.each_with_object({}) do |reaction, result|
          result[reaction.id] = articles_by_id[reaction.reactable_id]
        end
      end
    end
  end
end
