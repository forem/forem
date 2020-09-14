module DataUpdateScripts
  class ReindexUsersForProfiles
    def run
      User.find_each(&:index_to_elasticsearch_inline)
    end
  end
end
