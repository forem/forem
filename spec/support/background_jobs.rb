module BackgroundJobs
  def run_background_jobs_immediately
    Delayed::Worker.delay_jobs = false
    yield
    Delayed::Worker.delay_jobs = true
  end
end

RSpec.configure do |config|
  config.include BackgroundJobs
end
