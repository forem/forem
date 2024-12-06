# frozen_string_literal: true

module Ferrum
  module Utils
    module Attempt
      module_function

      def with_retry(errors:, max:, wait:)
        attempts ||= 1
        yield
      rescue *Array(errors)
        raise if attempts >= max

        attempts += 1
        sleep(wait)
        retry
      end
    end
  end
end
