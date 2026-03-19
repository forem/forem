module Slack
  module Messengers
    class ArticlePublished < Base

      def initialize(article:)
        @article = article
      end

      def call
        return unless article.published && article.published_at > 10.minutes.ago

        message = I18n.t(
          "services.slack.messengers.article_published.body",
          title: article.title,
          url: URL.article(article),
        )

        # [forem-fix] Remove channel name from Settings::General
        enqueue_slack_message(
          "message" => message,
          "channel" => Settings::General.article_published_slack_channel,
          "username" => "article_bot",
          "icon_emoji" => ":writing_hand:",
        )
      end

      private

      attr_reader :article
    end
  end
end
