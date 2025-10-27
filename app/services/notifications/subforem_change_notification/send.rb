# send notifications about a subforem change
module Notifications
  module SubforemChangeNotification
    class Send
      def self.call(...)
        new(...).call
      end

      def initialize(article:, old_subforem_id:, new_subforem_id:)
        @article = article
        @old_subforem_id = old_subforem_id
        @new_subforem_id = new_subforem_id
      end

      delegate :user_data, to: Notifications

      def call
        json_data = {
          user: user_data(User.mascot_account),
          article: { title: article.title, path: article.path },
          old_subforem: old_subforem_data,
          new_subforem: new_subforem_data,
          reason: "Your article was automatically moved to a more appropriate community based on its content."
        }
        Notification.create(
          user_id: article.user_id,
          notifiable_id: article.id,
          notifiable_type: "Article",
          action: "subforem_change",
          json_data: json_data,
        )
      end

      private

      attr_reader :article, :old_subforem_id, :new_subforem_id

      def old_subforem_data
        return unless old_subforem_id

        old_subforem = Subforem.find_by(id: old_subforem_id)
        return unless old_subforem

        {
          id: old_subforem.id,
          domain: old_subforem.domain,
          name: Settings::Community.community_name(subforem_id: old_subforem.id),
          misc: old_subforem.misc
        }
      end

      def new_subforem_data
        new_subforem = Subforem.find(new_subforem_id)
        {
          id: new_subforem.id,
          domain: new_subforem.domain,
          name: Settings::Community.community_name(subforem_id: new_subforem.id),
          misc: new_subforem.misc
        }
      end
    end
  end
end
