module Blazer
  class Statement
    attr_reader :statement, :data_source, :bind_statement, :bind_values
    attr_accessor :values

    def initialize(statement, data_source = nil)
      @statement = statement
      @data_source = data_source.is_a?(String) ? Blazer.data_sources[data_source] : data_source
      @values = {}
    end

    def variables
      @variables ||= Blazer.extract_vars(statement)
    end

    def add_values(var_params)
      variables.each do |var|
        value = var_params[var].presence
        value = nil unless value.is_a?(String) # ignore arrays and hashes
        if value
          if ["start_time", "end_time"].include?(var)
            value = value.to_s.gsub(" ", "+") # fix for Quip bug
          end

          if var.end_with?("_at")
            begin
              value = Blazer.time_zone.parse(value)
            rescue
              # do nothing
            end
          end

          unless value.is_a?(ActiveSupport::TimeWithZone)
            if value =~ /\A\d+\z/
              value = value.to_i
            elsif value =~ /\A\d+\.\d+\z/
              value = value.to_f
            end
          end
        end
        value = Blazer.transform_variable.call(var, value) if Blazer.transform_variable
        @values[var] = value
      end
    end

    def cohort_analysis?
      /\/\*\s*cohort analysis\s*\*\//i.match?(statement)
    end

    def apply_cohort_analysis(period:, days:)
      @statement = data_source.cohort_analysis_statement(statement, period: period, days: days).sub("{placeholder}") { statement }
    end

    # should probably transform before cohort analysis
    # but keep previous order for now
    def transformed_statement
      statement = self.statement.dup
      Blazer.transform_statement.call(data_source, statement) if Blazer.transform_statement
      statement
    end

    def bind
      @bind_statement, @bind_values = data_source.bind_params(transformed_statement, values)
    end

    def display_statement
      data_source.sub_variables(transformed_statement, values)
    end

    def clear_cache
      bind if bind_statement.nil?
      data_source.clear_cache(self)
    end
  end
end
