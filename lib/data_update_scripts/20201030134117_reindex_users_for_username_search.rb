module DataUpdateScripts
  class ReindexUsersForUsernameSearch
    def run
      # User.select(:id).in_batches(of: 200) do |batch|
      #   Search::BulkIndexWorker.set(queue: :default).perform_async("User", batch.ids)
      # end
    end
  end
end
