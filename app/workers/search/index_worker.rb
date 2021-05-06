module Search
  class IndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, lock: :until_executing

    def perform(_object_class, _id)
      # TODO: [@atsmith813] - delete this a few days after 05/03/2021
      # This is a no-op worker that we need for the removal of Elasticsearch
    end
  end
end
