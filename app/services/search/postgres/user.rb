module Search
  module Postgres
    class User
      HOTNESS_SCORE_ORDER =
        "(articles_count + comments_count + reactions_count + badge_achievements_count) * 10 * reputation_modifier DESC"
          .freeze

      SELECT_FIELDS = %i[
        badge_achievements_count
        comments_count
        id
        last_comment_at
        name
        profile_image
        reactions_count
        username
      ].freeze

      def self.search_documents(term: nil, page: 1, per_page: 20)
        page = (page || 1).to_i
        per_page = (per_page || 30).to_i

        # NOTE: [@rhymes] ES uses "exclusion" to exclude roles from the result,
        # to speed up this spike I'm hardcoding "everything except banned users",
        # we can build filters using `.with_role`/`.without_role` when we'll need them
        relation = ::User
          .without_role(:banned)

        # ES returns results even without the term
        relation = if term.present?
                     relation.search(term)
                   else
                     # if we don't use the FTS search we need to replicate the same ranking algorithm found in `User`
                     relation
                       # `hotness_score` doesn't exist in the DB, thus we need to calculate it at runtime
                       .order(Arel.sql(HOTNESS_SCORE_ORDER))
                       .order(badge_achievements_count: :desc)
                   end

        documents = relation
          .select(SELECT_FIELDS)
          .page(page)
          .per(per_page)

        # I'm inlining this because I don't think the format of the ES results is intuitive and as we're not
        # really using it anywhere, and as it's technically not part of the API, it might be simplified
        result = Jbuilder.new do |json|
          json.array!(documents) do |user|
            json.user do
              json.username user.username
              json.name user.username
              json.profile_image_90 user.profile_image_90
            end
            json.title user.name
            json.path user.path
            json.id user.id
            json.class_name "User"
            json.extract!(user, :public_reactions_count, :comments_count, :badge_achievements_count)
            json.last_comment_at user.last_comment_at.rfc3339(3)
            json.user_id user.id
          end
        end

        result.attributes!
      end
    end
  end
end
