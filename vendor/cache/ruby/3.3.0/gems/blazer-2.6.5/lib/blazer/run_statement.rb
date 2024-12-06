module Blazer
  class RunStatement
    def perform(statement, options = {})
      query = options[:query]

      data_source = statement.data_source
      statement.bind

      # audit
      if Blazer.audit
        audit_statement = statement.bind_statement
        audit_statement += "\n\n#{statement.bind_values.to_json}" if statement.bind_values.any?
        audit = Blazer::Audit.new(statement: audit_statement)
        audit.query = query
        audit.data_source = data_source.id
        audit.user = options[:user]
        audit.save!
      end

      start_time = Blazer.monotonic_time
      result = data_source.run_statement(statement, options)
      duration = Blazer.monotonic_time - start_time

      if Blazer.audit
        audit.duration = duration if audit.respond_to?(:duration=)
        audit.error = result.error if audit.respond_to?(:error=)
        audit.timed_out = result.timed_out? if audit.respond_to?(:timed_out=)
        audit.cached = result.cached? if audit.respond_to?(:cached=)
        if !result.cached? && duration >= 10
          audit.cost = data_source.cost(statement) if audit.respond_to?(:cost=)
        end
        audit.save! if audit.changed?
      end

      if query && !result.timed_out? && !query.variables.any?
        query.checks.each do |check|
          check.update_state(result)
        end
      end

      result
    end
  end
end
