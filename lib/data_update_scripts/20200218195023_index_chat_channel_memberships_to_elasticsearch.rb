module DataUpdateScripts
  class IndexChatChannelMembershipsToElasticsearch
    def run
      # ChatChannelMembership.find_each(&:index_to_elasticsearch_inline)
    end
  end
end
