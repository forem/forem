# frozen_string_literal: true

require "digest"

module Honeycomb
  ##
  # Provides a should_sample method which can be used for deterministic
  # sampling
  #
  module DeterministicSampler
    MAX_INT32 = 2**32 - 1

    def should_sample(rate, value)
      return true if rate == 1

      upper_bound = MAX_INT32 / rate
      digest = Digest::SHA1.digest(value)[0, 4]
      value = digest.unpack("I!>").first
      value <= upper_bound
    end
  end
end
