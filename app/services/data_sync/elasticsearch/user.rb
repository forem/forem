module DataSync
  module Elasticsearch
    class User < Base
      RELATED_DOCS = %i[
        articles
        podcast_episodes
        chat_channel_memberships
        comments
      ].freeze

      SHARED_FIELDS = %i[
        username
        name
        profile_image_url
      ].freeze

      delegate :articles, :chat_channel_memberships, :comments, to: :@updated_record

      private

      def reactions
        updated_record.reactions.readinglist
      end

      def podcast_episodes
        PodcastEpisode.for_user(updated_record)
      end
    end
  end
end
