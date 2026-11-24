module Api
  module FollowersController
    extend ActiveSupport::Concern

    include JsonApiSortParam

    USERS_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id follower_id follower_type created_at
    ].freeze
    private_constant :USERS_ATTRIBUTES_FOR_SERIALIZATION

    FOLLOWER_USER_COLUMNS = %i[id name username profile_image].freeze
    private_constant :FOLLOWER_USER_COLUMNS

    def users
      # Filtering `blocked: false` aligns the `created_at` sort with
      # `index_follows_on_followable_blocked_and_created_at` instead of scanning
      # `index_follows_on_created_at` or sorting `fk_followables` in memory.
      base_scope = Follow.non_suspended("User", @user.id)
        .where(blocked: false)
        .order(order_criteria)
        .page(params[:page])
        .per(@follows_limit)

      if native_followers_serializable? && (json_body = serialize_followers_natively(base_scope))
        render json: json_body
        return
      end

      @follows = base_scope
        .includes(:follower)
        .select(USERS_ATTRIBUTES_FOR_SERIALIZATION)
    end

    private

    def native_followers_serializable?
      ForemNative.available? &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?)
    end

    def serialize_followers_natively(scope)
      rows = scope.pluck(:id, :follower_id, :created_at)
      return "[]" if rows.empty?

      follower_ids = rows.pluck(1).uniq
      users_by_id = User.where(id: follower_ids).select(*FOLLOWER_USER_COLUMNS).index_by(&:id)

      followers_flat = []
      rows.each do |follow_id, follower_id, created_at|
        user = users_by_id[follower_id]
        return nil unless user
        return nil unless created_at.nil? || created_at.respond_to?(:tv_sec)

        followers_flat.push(
          follow_id,
          created_at&.tv_sec,
          user.id,
          user.name,
          user.path,
          user.username,
          user.profile_image_url_for(length: 60),
        )
      end

      ForemNative.serialize_api_followers_json(
        followers_flat,
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end

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
