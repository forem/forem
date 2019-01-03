RSpec.configure do |config|
  config.include ActiveJob::TestHelper

  config.before do
    clear_enqueued_jobs
  end
end

ActiveJob::Base.queue_adapter = :test
