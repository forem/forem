module Blazer
  class RunStatementJob < ActiveJob::Base
    self.queue_adapter = :async

    def perform(data_source_id, statement, options)
      statement = Blazer::Statement.new(statement, data_source_id)
      statement.values = options.delete(:values)
      data_source = statement.data_source
      begin
        ActiveRecord::Base.connection_pool.with_connection do
          Blazer::RunStatement.new.perform(statement, options)
        end
      rescue Exception => e
        Blazer::Result.new(data_source, [], [], "Unknown error", nil, false)
        Blazer.cache.write(data_source.run_cache_key(options[:run_id]), Marshal.dump([[], [], "Unknown error", nil]), expires_in: 30.seconds)
        raise e
      end
    end
  end
end
