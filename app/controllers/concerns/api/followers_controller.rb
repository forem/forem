module Api
  module FollowersController
    extend ActiveSupport::Concern

    include JsonApiSortParam

    USERS_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id follower_id follower_type created_at
    ].freeze
    private_constant :USERS_ATTRIBUTES_FOR_SERIALIZATION

    def users
      @follows = Follow.non_suspended("User", @user.id)
        .includes(:follower)
        .select(USERS_ATTRIBUTES_FOR_SERIALIZATION)
        .order(order_criteria)
        .page(params[:page])
        .per(@follows_limit)
    end

    private

    def limit_per_page(default:, max:)
      per_page = (params[:per_page] || default).to_i
      @follows_limit = [per_page, max].min
    end

    def order_criteria
      parse_sort_param(
        allowed_fields: [:created_at],
        default_sort: { created_at: :desc },
      )
    end
  end
end
