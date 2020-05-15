SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end
