module Slack
  module Messengers
    class ArticlePublished
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        New Article Published: %<title>s
        %<url>s
      TEXT

      def initialize(article:)
        @article = article
      end

      def self.call(**args)
        new(**args).call
      end

      def call
        return unless article.published && article.published_at > 30.seconds.ago

        message = format(
          MESSAGE_TEMPLATE,
          title: article.title,
          url: URL.article(article),
        )

        Slack::Messengers::Worker.perform_async(
          message: message,
          channel: "activity",
          username: "article_bot",
          icon_emoji: ":writing_hand:",
        )
      end

      private

      attr_reader :article
    end
  end
end
