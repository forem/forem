class DataUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high_priority, retry: 5

  def perform
    script_ids = DataUpdateScript.load_script_ids
    scripts_to_run = DataUpdateScript.where(id: script_ids).select(&:enqueued?)

    scripts_to_run.each do |script|
      script.mark_as_run!
      run_script(script)
    end
  end

  private

  def run_script(script)
    require script.file_path
    script.file_class.new.run
    script.mark_as_finished!
  rescue StandardError => e
    script.mark_as_failed!
    Honeybadger.notify(e, context: { script_id: script.id })
  end
end
