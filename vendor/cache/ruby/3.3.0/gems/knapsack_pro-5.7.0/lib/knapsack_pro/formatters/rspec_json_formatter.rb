# frozen_string_literal: true

RSpec::Support.require_rspec_core('formatters/json_formatter')

# based on https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/formatters/json_formatter.rb
module KnapsackPro
  module Formatters
    class RSpecJsonFormatter < ::RSpec::Core::Formatters::JsonFormatter
      ::RSpec::Core::Formatters.register self

      private

      # add example.id to json report to support < RSpec 3.6.0
      # based on https://github.com/rspec/rspec-core/pull/2369/files
      def format_example(example)
        super.merge({
          :id => example.id,
        })
      end
    end
  end
end
