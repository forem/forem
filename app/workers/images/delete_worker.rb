# app/workers/images/delete_worker.rb

module Images
  class DeleteWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 5

    def perform(image_path)
      Images::Delete.call(image_path)
    end
  end
end
