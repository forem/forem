require "mini_magick"

# Carrierwave uses MiniMagick for image processing. To prevent server timeouts
# we are setting the MiniMagick timeout lower.
MiniMagick.configure do |config|
  config.timeout = 10
end

module MiniMagickShellTimeoutGuard
  # Leave headroom before Rack::Timeout raises RequestTimeoutException (an Exception
  # subclass) so MiniMagick raises Timeout::Error (a StandardError subclass that
  # uploaders can rescue gracefully) and cleans up the child process first.
  RACK_TIMEOUT_HEADROOM_SECONDS = 1.0
  CHILD_TERM_GRACE_SECONDS = 2

  # Computes the timeout (in seconds) for a MiniMagick subprocess, capped to
  # leave headroom before Rack::Timeout aborts the enclosing request.
  def self.effective_timeout
    configured = MiniMagick.timeout
    return configured unless defined?(RackTimeoutThreadTracker)

    remaining = RackTimeoutThreadTracker.remaining_timeout
    return configured unless remaining

    budget = remaining - RACK_TIMEOUT_HEADROOM_SECONDS
    return budget if configured.nil?

    [configured.to_f, budget].min
  end

  private

  # Executes the command via Open3.popen3 with a request-budget-aware timeout
  # and guaranteed child process termination in ensure.
  # Matches MiniMagick::Shell#execute_open3(command, options = {}) signature.
  def execute_open3(command, options = {}) # rubocop:disable Style/OptionHash
    timeout = MiniMagickShellTimeoutGuard.effective_timeout
    if timeout && timeout <= 0
      raise Timeout::Error, "MiniMagick command timed out before execution (insufficient request budget): #{command}"
    end

    require "open3"

    Open3.popen3(*command) do |in_w, out_r, err_r, thread|
      [in_w, out_r, err_r].each(&:binmode)
      stdout_reader = Thread.new { out_r.read }
      stderr_reader = Thread.new { err_r.read }
      begin
        in_w.write options[:stdin].to_s
      rescue Errno::EPIPE
        nil
      end
      in_w.close

      unless thread.join(timeout)
        terminate_child_process(thread)
        raise Timeout::Error, "MiniMagick command timed out: #{command}"
      end

      [stdout_reader.value, stderr_reader.value, thread.value]
    ensure
      terminate_child_process(thread) if thread&.alive?
      stdout_reader.kill if stdout_reader&.alive?
      stderr_reader.kill if stderr_reader&.alive?
    end
  end

  # Sends SIGTERM to the child process and waits on the Open3 waiter thread up to
  # CHILD_TERM_GRACE_SECONDS, escalating to SIGKILL if it is still alive.
  def terminate_child_process(thread)
    return unless thread&.alive?

    begin
      Process.kill("TERM", thread.pid)
      return if thread.join(CHILD_TERM_GRACE_SECONDS)

      Process.kill("KILL", thread.pid)
      thread.join(CHILD_TERM_GRACE_SECONDS)
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end
  end
end

MiniMagick::Shell.prepend(MiniMagickShellTimeoutGuard)

module CarrierWaveInitializer
  def self.local_storage_config
    CarrierWave.configure do |config|
      config.storage = :file
      config.enable_processing = !Rails.env.test? # disabled for test
      config.move_to_store = Rails.env.test?
      config.asset_host = if Rails.env.production?
                            "https://#{ApplicationConfig['APP_DOMAIN']}"
                          end
    end
  end

  def self.standard_production_config
    CarrierWave.configure do |config|
      config.storage = :fog
      config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
      config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
      config.fog_credentials = {
        provider: "AWS",
        aws_access_key_id: ApplicationConfig["AWS_ID"],
        aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
        region: ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
      }
    end
  end

  def self.forem_cloud_config
    CarrierWave.configure do |config|
      config.storage = :fog
      config.fog_directory = ApplicationConfig["AWS_BUCKET_NAME"]
      config.asset_host = "https://#{ApplicationConfig['APP_DOMAIN']}/remoteimages"
      config.fog_public = false
      config.fog_credentials = {
        provider: "AWS",
        use_iam_profile: true,
        region: "us-east-2"
      }
    end
  end

  def self.initialize!
    if Rails.env.production? && ENV["FILE_STORAGE_LOCATION"] != "file"
      if ENV["FOREM_CONTEXT"] == "forem_cloud"
        forem_cloud_config
      elsif ApplicationConfig["AWS_ID"].present?
        standard_production_config
      else
        local_storage_config
      end
    else
      local_storage_config
    end
  end
end

Rails.application.reloader.to_prepare do
  CarrierWaveInitializer.initialize!
end
