module Suggester
  module Users
    class Recent
      attr_accessor :user
      def initialize(user)
        @user = user
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
        User.where(id: tagged_article_user_ids(num_weeks)).order("updated_at DESC").limit(80).to_a
      end

      def recent_top_producers
        User.where("articles_count > ? AND comments_count > ?",
                   established_user_article_count, established_user_comment_count).
          order("updated_at DESC").limit(50).to_a
      end

      def recent_commenters(num_coumments = 2, limit = 8)
        User.where("comments_count > ?", num_coumments).order("updated_at DESC").limit(limit).to_a
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
