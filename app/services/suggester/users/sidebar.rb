module Suggester
  module Users
    class Sidebar
      def initialize(user, given_tag)
        @user = user
        @given_tag = given_tag
      end

      def suggest
        Rails.cache.fetch(generate_cache_name, expires_in: 120.hours) do
          reaction_count = Rails.env.production? ? 25 : 0
          user_ids = Article.published.tagged_with([given_tag], any: true).
            where("positive_reactions_count > ?", reaction_count).
            where("published_at > ?", 4.months.ago).
            where("user_id != ?", user.id).
            where.not(user_id: user.following_by_type("User")).
            pluck(:user_id)
          group_one = User.select(:id, :name, :username, :profile_image, :summary).
            where(id: user_ids).
            order("reputation_modifier DESC").limit(20).to_a
          group_two = User.select(:id, :name, :username, :profile_image, :summary).
            where(id: user_ids).
            order(Arel.sql("RANDOM()")).limit(20).to_a
          (group_one + group_two).uniq
        end
      end

      private

      attr_reader :user, :given_tag

      def generate_cache_name
        "tag-#{given_tag}_user-#{user.id}-#{user.last_followed_at}/tag-follow-sugggestions"
      end
    end
  end
end
