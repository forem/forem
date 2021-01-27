class DataUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high_priority, retry: 5

  def perform
    DataUpdateScript.scripts_to_run.each do |script|
      script.mark_as_run!
      log_status(script)

      run_script(script)
    end
  end

  private

  def run_script(script)
    require script.file_path

    script.file_class.new.run

    script.mark_as_finished!
    log_status(script)
  rescue StandardError => e
    script.mark_as_failed!(e)
    log_status(script)

    Honeybadger.notify(e, context: { script_id: script.id })
  end

  def log_status(script)
    status = script.status
    file_name = script.file_name

    logger_destination = status.to_sym == :failed ? :error : :info
    Rails.logger.public_send(
      logger_destination,
      "time=#{Time.current.rfc3339}, script=#{file_name}, status=#{status}",
    )

    ForemStatsClient.increment("data_update_scripts.status", tags: ["status:#{status}", "script_name:#{file_name}"])
  end
end
