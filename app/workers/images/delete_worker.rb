# app/workers/images/delete_worker.rb

module Images
  class DeleteImageWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 5

    def perform(image_paths)
      Images::Delete.call(image_paths)
    end
  end
end
