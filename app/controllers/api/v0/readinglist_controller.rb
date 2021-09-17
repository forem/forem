module Api
  module V0
    class ReadinglistController < ApiController
      before_action :authenticate!
      before_action -> { doorkeeper_authorize! :public }, only: %w[index], if: -> { doorkeeper_token }

      INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION = %i[id reactable_id created_at status].freeze
      private_constant :INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION

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
          .select(ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION)
          .where(id: @readinglist.map(&:reactable_id))
          .decorate

        @users_by_id = User
          .joins(:profile)
          .select(UsersController::SHOW_ATTRIBUTES_FOR_SERIALIZATION)
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
