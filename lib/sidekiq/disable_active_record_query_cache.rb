module Sidekiq
  class DisableActiveRecordQueryCache
    def call(*_args, &block)
      ActiveRecord::Base.connection.uncached(&block)
    end
  end
end
