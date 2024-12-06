# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  add_filter "_spec.rb"
end

SimpleCov.minimum_coverage(line: 98, branch: 75)
