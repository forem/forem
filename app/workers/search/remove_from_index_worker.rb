module Search
  class RemoveFromIndexWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 10

    def perform(index, key)
      Algolia::Index.new(index).delete_object(key)
    end
  end
end
