module Notifications
  module Milestone
    ARTICLE_FINAL_PUBLICATION_TIME_FOR_MILESTONE = Time.zone.local(2019, 2, 25)

    class Send
      # @param type [String] - "View" or "Reaction"
      # @param article [Object] - ActiveRecord Article object
      def initialize(type, article)
        @type = type
        @article = article
        @next_milestone = next_milestone
      end

      def self.call(...)
        new(...).call
      end

      def call
        return unless should_send_milestone?

        create_notification(user_id: article.user_id)
        return unless article.organization_id

        create_notification(organization_id: article.organization_id)
      end

      private

      attr_reader :type, :article

      def create_notification(hash_id)
        Notification.create!({
          notifiable_id: article.id,
          notifiable_type: "Article",
          json_data: json_data,
          action: "Milestone::#{type}::#{@next_milestone}"
        }.merge(hash_id))
      end

      def json_data
        gif_id = Constants::RandomGifs::IDS.sample
        { article: Notifications.article_data(article), gif_id: gif_id }
      end

      def article_published_behind_time?
        article.published_at < ARTICLE_FINAL_PUBLICATION_TIME_FOR_MILESTONE
      end

      def should_send_milestone?
        return if article_published_behind_time?

        last_milestone_notification = Notification.find_by(
          user_id: article.user_id,
          notifiable_type: "Article",
          notifiable_id: article.id,
          action: "Milestone::#{type}::#{@next_milestone}",
        )

        case type
        when "View"
          last_milestone_notification.blank? && article.page_views_count > @next_milestone
        when "Reaction"
          last_milestone_notification.blank? && article.public_reactions_count > @next_milestone
        end
      end

      def next_milestone
        case type
        when "View"
          milestones = [1024, 2048, 4096, 8192, 16_384, 32_768, 65_536, 131_072, 262_144, 524_288, 1_048_576]
          milestone_count = article.page_views_count
        when "Reaction"
          milestones = [64, 128, 256, 512, 1024, 2048, 4096, 8192]
          milestone_count = article.public_reactions_count
        end

        closest_number = milestones.min_by { |num| (milestone_count - num).abs }
        if milestone_count > closest_number
          closest_number
        else
          milestones[milestones.index(closest_number) - 1]
        end
      end
    end
  end
end
