module Slack
  module Messengers
    class ArticleFetchedFeed
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        New Article Retrieved via RSS: %<title>s
        %<url>s
      TEXT

      def initialize(article:)
        @article = article
      end

      def self.call(...)
        new(...).call
      end

      def call
        return unless article.published_from_feed?

        message = format(
          MESSAGE_TEMPLATE,
          title: article.title,
          url: URL.article(article),
        )

        Slack::Messengers::Worker.perform_async(
          message: message,
          channel: "activity",
          username: "article_bot",
          icon_emoji: ":robot_face:",
        )
      end

      private

      attr_reader :article
    end
  end
end
