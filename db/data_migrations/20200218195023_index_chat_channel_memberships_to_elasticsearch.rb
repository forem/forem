class IndexChatChannelMembershipsToElasticsearch < ActiveRecord::DataMigration
  def up
    ChatChannelMembership.find_each(&:index_to_elasticsearch_inline)
  end
end
