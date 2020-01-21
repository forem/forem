module Search
  class RemoveFromIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(index, key)
      return unless index && key

      Algolia::Index.new(index).delete_object(key)
    end
  end
end
