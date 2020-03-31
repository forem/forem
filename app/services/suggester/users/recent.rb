module Suggester
  module Users
    class Recent
      def initialize(user, attributes_to_select: [])
        @user = user
        @attributes_to_select = attributes_to_select
      end

      def suggest
        users = if user.decorate.cached_followed_tag_names.any?
                  (recent_producers(3) - [user]).
                    sample(50).uniq
                else
                  (recent_commenters(4, 30) + recent_top_producers - [user]).
                    uniq.sample(50)
                end
        users
      end

      private

      attr_reader :user, :attributes_to_select

      def tagged_article_user_ids(num_weeks = 1)
        Article.published.
          tagged_with(user.decorate.cached_followed_tag_names, any: true).
          where("score > ? AND published_at > ?", article_reaction_count, num_weeks.weeks.ago).
          pluck(:user_id).
          each_with_object(Hash.new(0)) { |value, counts| counts[value] += 1 }.
          sort_by { |_key, value| value }.
          map { |arr| arr[0] }
      end

      def recent_producers(num_weeks = 1)
        relation = User.where(id: tagged_article_user_ids(num_weeks))
        relation = relation.select(attributes_to_select) if attributes_to_select

        relation.order("updated_at DESC").limit(80).to_a
      end

      def recent_top_producers
        relation = User.where(
          "articles_count > ? AND comments_count > ?",
          established_user_article_count, established_user_comment_count
        )
        relation = relation.select(attributes_to_select) if attributes_to_select

        relation.order("updated_at DESC").limit(50).to_a
      end

      def recent_commenters(num_comments = 2, limit = 8)
        relation = User.where("comments_count > ?", num_comments)
        relation = relation.select(attributes_to_select) if attributes_to_select

        relation.order("updated_at DESC").limit(limit).to_a
      end

      def established_user_article_count
        Rails.env.production? ? 4 : -1
      end

      def established_user_comment_count
        Rails.env.production? ? 4 : -1
      end

      def article_reaction_count
        Rails.env.production? ? 15 : -1
      end
    end
  end
end
