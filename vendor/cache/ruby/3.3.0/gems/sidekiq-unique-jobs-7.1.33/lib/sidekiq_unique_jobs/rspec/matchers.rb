# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # We all know what the hell RSpec is no?
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  module RSpec
    #
    # Module Matchers provides RSpec matcher for your workers
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module Matchers
    end
  end
end

if defined?(RSpec)
  require_relative "matchers/have_valid_sidekiq_options"

  RSpec.configure do |config|
    config.include SidekiqUniqueJobs::RSpec::Matchers
  end
end
