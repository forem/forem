require 'rspec/its'
require 'spinach'

require 'timecop'
Timecop.safe_mode = true

require 'vcr'
require 'webmock/rspec'
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock # or :fakeweb
  config.ignore_hosts('codeclimate.com')
end

require 'knapsack_pro'

Dir["#{KnapsackPro.root}/spec/{support,fixtures}/**/*.rb"].each { |f| require f }

KNAPSACK_PRO_TMP_DIR = File.join(KnapsackPro.root, '.knapsack_pro')

RSpec.configure do |config|
  config.order = :random
  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    if RSpec.current_example.metadata[:clear_tmp]
      FileUtils.rm_r(KNAPSACK_PRO_TMP_DIR) if File.exist?(KNAPSACK_PRO_TMP_DIR)
      FileUtils.mkdir_p(KNAPSACK_PRO_TMP_DIR)
    end
  end

  config.after(:each) do
    if RSpec.current_example.metadata[:clear_tmp]
      FileUtils.rm_r(KNAPSACK_PRO_TMP_DIR) if File.exist?(KNAPSACK_PRO_TMP_DIR)
    end
  end
end
