require "rbconfig"

module LocalRedis
  # Keep Puma alive through optional cache failures; restart auxiliaries with
  # backoff. All children receive TERM, including outside Heroku's process group.
  class Web
    def initialize(command:, cache_commands: nil)
      @commands = (cache_commands || {
        redis: [RbConfig.ruby, "bin/redis-local-server"],
        sync: [RbConfig.ruby, "bin/redis-local-sync"]
      }).merge(web: command)
      @children = {}
      @restart_at = {}
      @stopping = false
    end

    def run
      %w[TERM INT].each { |signal| Signal.trap(signal) { @stopping = true } }
      @commands.each_key { |role| start(role) }
      until @stopping
        reap
        @restart_at.each do |role, deadline|
          next if Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline

          start(role)
          @restart_at.delete(role)
        end
        sleep 0.1
      end
      @exit_status || 0
    ensure
      shutdown
    end

    private

    def start(role)
      @children[Process.spawn(*@commands.fetch(role))] = role
    end

    def reap
      loop do
        pid, status = Process.waitpid2(-1, Process::WNOHANG)
        break unless pid

        role = @children.delete(pid)
        if role == :web
          @exit_status = status.exitstatus || 1
          @stopping = true
        elsif role && !@stopping
          warn "LocalRedis #{role} exited; restarting in 2s (Puma continues using authoritative Redis)"
          @restart_at[role] = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
        end
      end
    rescue Errno::ECHILD
      @stopping = true
    end

    def shutdown
      @children.each_key { |pid| signal("TERM", pid) }
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 28
      until @children.empty? || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        reap
        sleep 0.1
      end
      @children.each_key do |pid|
        signal("KILL", pid)
        Process.waitpid(pid)
      rescue Errno::ECHILD
        nil
      end
    end

    def signal(signal, pid)
      Process.kill(signal, pid)
    rescue Errno::ESRCH
      nil
    end
  end
end
