require 'memoizable'

module Twitter
  class RateLimit < Twitter::Base
    include Memoizable

    # @return [Integer]
    def limit
      limit = @attrs['x-rate-limit-limit']
      limit&.to_i
    end
    memoize :limit

    # @return [Integer]
    def remaining
      remaining = @attrs['x-rate-limit-remaining']
      remaining&.to_i
    end
    memoize :remaining

    # @return [Time]
    def reset_at
      reset = @attrs['x-rate-limit-reset']
      Time.at(reset.to_i).utc if reset
    end
    memoize :reset_at

    # @return [Integer]
    def reset_in
      [(reset_at - Time.now).ceil, 0].max if reset_at
    end
    alias retry_after reset_in
  end
end
