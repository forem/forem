class ExternalService
  class << self
    def start_service
      @job_pid = fork {
        exec "yarn start"
      }
      Process.detach(@job_pid)
    end
  end
end
