module AlgoliaSearch
  class AlgoliaJob < ::ActiveJob::Base
    queue_as { AlgoliaSearch.configuration[:queue_name] }

    def perform(record, method)
      record.send(method)
    end
  end
end
