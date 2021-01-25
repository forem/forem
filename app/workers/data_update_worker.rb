class DataUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high_priority, retry: 5

  def perform
    DataUpdateScript.scripts_to_run.each do |script|
      script.mark_as_run!
      script.log_status
      script.run_script
    end
  end
end
