module Search
  class ChatChannelMembership < Base
    INDEX_NAME = "chat_channel_memberships_#{Rails.env}".freeze
    INDEX_ALIAS = "chat_channel_memberships_#{Rails.env}_alias".freeze
    MAPPINGS = JSON.parse(File.read("config/elasticsearch/mappings/chat_channel_memberships.json"),
                          symbolize_names: true).freeze
    DEFAULT_PAGE = 0
    DEFAULT_PER_PAGE = 30

    class << self
      private

      def index_settings
        if Rails.env.production?
          {
            number_of_shards: 3,
            number_of_replicas: 1
          }
        else
          {
            number_of_shards: 1,
            number_of_replicas: 0
          }
        end
      end
    end
  end
end
