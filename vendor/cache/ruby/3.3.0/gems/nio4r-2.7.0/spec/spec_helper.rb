# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2011-2017, by Tony Arcieri.
# Copyright, 2017, by Gregory Longtin.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2021, by Joao Fernandes.

require "nio"
require "support/selectable_examples"

RSpec.configure do |config|
  config.disable_monkey_patching!

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.filter_run_when_matching :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
