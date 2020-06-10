module Suggester
  module Users
    class Sidebar
      def initialize(user, given_tag)
        @user = user
        @given_tag = given_tag
        @minimum_reaction_count = Rails.env.production? ? 25 : -1 # -1 for when public_reactions_count is 0
      end

      def suggest
        suggested_user_ids = Rails.cache.fetch(generate_cache_name, expires_in: 120.hours) do
          (reputable_user_ids + random_user_ids).uniq
        end
        User.select(:id, :name, :username, :profile_image, :summary).where(id: suggested_user_ids).to_a
      end

      private

      attr_reader :user, :given_tag, :minimum_reaction_count

      def generate_cache_name
        "tag-#{given_tag}-user-#{user.id}-#{user.last_followed_at}/tag-follow-sugggestions"
      end

      def active_authors_for_given_tags
        @active_authors_for_given_tags ||= Article.published.tagged_with([given_tag], any: true).
          where("public_reactions_count > ?", minimum_reaction_count).
          where("published_at > ?", 4.months.ago).
          where("user_id != ?", user.id).
          where.not(user_id: user.following_by_type("User")).
          pluck(:user_id)
      end

      def reputable_user_ids
        User.where(id: active_authors_for_given_tags).order("reputation_modifier DESC").limit(20).pluck(:id).to_a
      end

      def random_user_ids
        User.where(id: active_authors_for_given_tags).order(Arel.sql("RANDOM()")).limit(20).pluck(:id).to_a
      end
    end
  end
end
