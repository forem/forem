module DataUpdateScripts
  class IndexUsersToElasticsearch
    def run
      User.select(:id).find_each do |user|
        Search::IndexToElasticsearchWorker.set(queue: :low_priority).perform_async(
          "User", user.id
        )
      end
    end
  end
end
