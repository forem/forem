# frozen_string_literal: true

require 'puma/runner'
require 'puma/util'
require 'puma/plugin'
require 'puma/cluster/worker_handle'
require 'puma/cluster/worker'

require 'time'

module Puma
  # This class is instantiated by the `Puma::Launcher` and used
  # to boot and serve a Ruby application when puma "workers" are needed
  # i.e. when using multi-processes. For example `$ puma -w 5`
  #
  # An instance of this class will spawn the number of processes passed in
  # via the `spawn_workers` method call. Each worker will have it's own
  # instance of a `Puma::Server`.
  class Cluster < Runner
    def initialize(cli, events)
      super cli, events

      @phase = 0
      @workers = []
      @next_check = Time.now

      @phased_restart = false
    end

    def stop_workers
      log "- Gracefully shutting down workers..."
      @workers.each { |x| x.term }

      begin
        loop do
          wait_workers
          break if @workers.reject {|w| w.pid.nil?}.empty?
          sleep 0.2
        end
      rescue Interrupt
        log "! Cancelled waiting for workers"
      end
    end

    def start_phased_restart
      @events.fire_on_restart!
      @phase += 1
      log "- Starting phased worker restart, phase: #{@phase}"

      # Be sure to change the directory again before loading
      # the app. This way we can pick up new code.
      dir = @launcher.restart_dir
      log "+ Changing to #{dir}"
      Dir.chdir dir
    end

    def redirect_io
      super

      @workers.each { |x| x.hup }
    end

    def spawn_workers
      diff = @options[:workers] - @workers.size
      return if diff < 1

      master = Process.pid
      if @options[:fork_worker]
        @fork_writer << "-1\n"
      end

      diff.times do
        idx = next_worker_index

        if @options[:fork_worker] && idx != 0
          @fork_writer << "#{idx}\n"
          pid = nil
        else
          pid = spawn_worker(idx, master)
        end

        debug "Spawned worker: #{pid}"
        @workers << WorkerHandle.new(idx, pid, @phase, @options)
      end

      if @options[:fork_worker] &&
        @workers.all? {|x| x.phase == @phase}

        @fork_writer << "0\n"
      end
    end

    # @version 5.0.0
    def spawn_worker(idx, master)
      @launcher.config.run_hooks :before_worker_fork, idx, @launcher.events

      pid = fork { worker(idx, master) }
      if !pid
        log "! Complete inability to spawn new workers detected"
        log "! Seppuku is the only choice."
        exit! 1
      end

      @launcher.config.run_hooks :after_worker_fork, idx, @launcher.events
      pid
    end

    def cull_workers
      diff = @workers.size - @options[:workers]
      return if diff < 1
      debug "Culling #{diff} workers"

      workers = workers_to_cull(diff)
      debug "Workers to cull: #{workers.inspect}"

      workers.each do |worker|
        log "- Worker #{worker.index} (PID: #{worker.pid}) terminating"
        worker.term
      end
    end

    def workers_to_cull(diff)
      workers = @workers.sort_by(&:started_at)

      # In fork_worker mode, worker 0 acts as our master process.
      # We should avoid culling it to preserve copy-on-write memory gains.
      workers.reject! { |w| w.index == 0 } if @options[:fork_worker]

      workers[cull_start_index(diff), diff]
    end

    def cull_start_index(diff)
      case @options[:worker_culling_strategy]
      when :oldest
        0
      else # :youngest
        -diff
      end
    end

    # @!attribute [r] next_worker_index
    def next_worker_index
      occupied_positions = @workers.map(&:index)
      idx = 0
      idx += 1 until !occupied_positions.include?(idx)
      idx
    end

    def all_workers_booted?
      @workers.count { |w| !w.booted? } == 0
    end

    def check_workers
      return if @next_check >= Time.now

      @next_check = Time.now + @options[:worker_check_interval]

      timeout_workers
      wait_workers
      cull_workers
      spawn_workers

      if all_workers_booted?
        # If we're running at proper capacity, check to see if
        # we need to phase any workers out (which will restart
        # in the right phase).
        #
        w = @workers.find { |x| x.phase != @phase }

        if w
          log "- Stopping #{w.pid} for phased upgrade..."
          unless w.term?
            w.term
            log "- #{w.signal} sent to #{w.pid}..."
          end
        end
      end

      @next_check = [
        @workers.reject(&:term?).map(&:ping_timeout).min,
        @next_check
      ].compact.min
    end

    def worker(index, master)
      @workers = []

      @master_read.close
      @suicide_pipe.close
      @fork_writer.close

      pipes = { check_pipe: @check_pipe, worker_write: @worker_write }
      if @options[:fork_worker]
        pipes[:fork_pipe] = @fork_pipe
        pipes[:wakeup] = @wakeup
      end

      server = start_server if preload?
      new_worker = Worker.new index: index,
                              master: master,
                              launcher: @launcher,
                              pipes: pipes,
                              server: server
      new_worker.run
    end

    def restart
      @restart = true
      stop
    end

    def phased_restart
      return false if @options[:preload_app]

      @phased_restart = true
      wakeup!

      true
    end

    def stop
      @status = :stop
      wakeup!
    end

    def stop_blocked
      @status = :stop if @status == :run
      wakeup!
      @control.stop(true) if @control
      Process.waitall
    end

    def halt
      @status = :halt
      wakeup!
    end

    def reload_worker_directory
      dir = @launcher.restart_dir
      log "+ Changing to #{dir}"
      Dir.chdir dir
    end

    # Inside of a child process, this will return all zeroes, as @workers is only populated in
    # the master process.
    # @!attribute [r] stats
    def stats
      old_worker_count = @workers.count { |w| w.phase != @phase }
      worker_status = @workers.map do |w|
        {
          started_at: w.started_at.utc.iso8601,
          pid: w.pid,
          index: w.index,
          phase: w.phase,
          booted: w.booted?,
          last_checkin: w.last_checkin.utc.iso8601,
          last_status: w.last_status,
        }
      end

      {
        started_at: @started_at.utc.iso8601,
        workers: @workers.size,
        phase: @phase,
        booted_workers: worker_status.count { |w| w[:booted] },
        old_workers: old_worker_count,
        worker_status: worker_status,
      }
    end

    def preload?
      @options[:preload_app]
    end

    # @version 5.0.0
    def fork_worker!
      if (worker = @workers.find { |w| w.index == 0 })
        worker.phase += 1
      end
      phased_restart
    end

    # We do this in a separate method to keep the lambda scope
    # of the signals handlers as small as possible.
    def setup_signals
      if @options[:fork_worker]
        Signal.trap "SIGURG" do
          fork_worker!
        end

        # Auto-fork after the specified number of requests.
        if (fork_requests = @options[:fork_worker].to_i) > 0
          @launcher.events.register(:ping!) do |w|
            fork_worker! if w.index == 0 &&
              w.phase == 0 &&
              w.last_status[:requests_count] >= fork_requests
          end
        end
      end

      Signal.trap "SIGCHLD" do
        wakeup!
      end

      Signal.trap "TTIN" do
        @options[:workers] += 1
        wakeup!
      end

      Signal.trap "TTOU" do
        @options[:workers] -= 1 if @options[:workers] >= 2
        wakeup!
      end

      master_pid = Process.pid

      Signal.trap "SIGTERM" do
        # The worker installs their own SIGTERM when booted.
        # Until then, this is run by the worker and the worker
        # should just exit if they get it.
        if Process.pid != master_pid
          log "Early termination of worker"
          exit! 0
        else
          @launcher.close_binder_listeners

          stop_workers
          stop
          @events.fire_on_stopped!
          raise(SignalException, "SIGTERM") if @options[:raise_exception_on_sigterm]
          exit 0 # Clean exit, workers were stopped
        end
      end
    end

    def run
      @status = :run

      output_header "cluster"

      # This is aligned with the output from Runner, see Runner#output_header
      log "*      Workers: #{@options[:workers]}"

      if preload?
        # Threads explicitly marked as fork safe will be ignored. Used in Rails,
        # but may be used by anyone. Note that we need to explicit
        # Process::Waiter check here because there's a bug in Ruby 2.6 and below
        # where calling thread_variable_get on a Process::Waiter will segfault.
        # We can drop that clause once those versions of Ruby are no longer
        # supported.
        fork_safe = ->(t) { !t.is_a?(Process::Waiter) && t.thread_variable_get(:fork_safe) }

        before = Thread.list.reject(&fork_safe)

        log "*     Restarts: (\u2714) hot (\u2716) phased"
        log "* Preloading application"
        load_and_bind

        after = Thread.list.reject(&fork_safe)

        if after.size > before.size
          threads = (after - before)
          if threads.first.respond_to? :backtrace
            log "! WARNING: Detected #{after.size-before.size} Thread(s) started in app boot:"
            threads.each do |t|
              log "! #{t.inspect} - #{t.backtrace ? t.backtrace.first : ''}"
            end
          else
            log "! WARNING: Detected #{after.size-before.size} Thread(s) started in app boot"
          end
        end
      else
        log "*     Restarts: (\u2714) hot (\u2714) phased"

        unless @launcher.config.app_configured?
          error "No application configured, nothing to run"
          exit 1
        end

        @launcher.binder.parse @options[:binds], self
      end

      read, @wakeup = Puma::Util.pipe

      setup_signals

      # Used by the workers to detect if the master process dies.
      # If select says that @check_pipe is ready, it's because the
      # master has exited and @suicide_pipe has been automatically
      # closed.
      #
      @check_pipe, @suicide_pipe = Puma::Util.pipe

      # Separate pipe used by worker 0 to receive commands to
      # fork new worker processes.
      @fork_pipe, @fork_writer = Puma::Util.pipe

      log "Use Ctrl-C to stop"

      single_worker_warning

      redirect_io

      Plugins.fire_background

      @launcher.write_state

      start_control

      @master_read, @worker_write = read, @wakeup

      @launcher.config.run_hooks :before_fork, nil, @launcher.events
      Puma::Util.nakayoshi_gc @events if @options[:nakayoshi_fork]

      spawn_workers

      Signal.trap "SIGINT" do
        stop
      end

      begin
        booted = false
        in_phased_restart = false
        workers_not_booted = @options[:workers]

        while @status == :run
          begin
            if @phased_restart
              start_phased_restart
              @phased_restart = false
              in_phased_restart = true
              workers_not_booted = @options[:workers]
            end

            check_workers

            if read.wait_readable([0, @next_check - Time.now].max)
              req = read.read_nonblock(1)

              @next_check = Time.now if req == "!"
              next if !req || req == "!"

              result = read.gets
              pid = result.to_i

              if req == "b" || req == "f"
                pid, idx = result.split(':').map(&:to_i)
                w = @workers.find {|x| x.index == idx}
                w.pid = pid if w.pid.nil?
              end

              if w = @workers.find { |x| x.pid == pid }
                case req
                when "b"
                  w.boot!
                  log "- Worker #{w.index} (PID: #{pid}) booted in #{w.uptime.round(2)}s, phase: #{w.phase}"
                  @next_check = Time.now
                  workers_not_booted -= 1
                when "e"
                  # external term, see worker method, Signal.trap "SIGTERM"
                  w.term!
                when "t"
                  w.term unless w.term?
                when "p"
                  w.ping!(result.sub(/^\d+/,'').chomp)
                  @launcher.events.fire(:ping!, w)
                  if !booted && @workers.none? {|worker| worker.last_status.empty?}
                    @launcher.events.fire_on_booted!
                    booted = true
                  end
                end
              else
                log "! Out-of-sync worker list, no #{pid} worker"
              end
            end
            if in_phased_restart && workers_not_booted.zero?
              @events.fire_on_booted!
              in_phased_restart = false
            end

          rescue Interrupt
            @status = :stop
          end
        end

        stop_workers unless @status == :halt
      ensure
        @check_pipe.close
        @suicide_pipe.close
        read.close
        @wakeup.close
      end
    end

    private

    def single_worker_warning
      return if @options[:workers] != 1 || @options[:silence_single_worker_warning]

      log "! WARNING: Detected running cluster mode with 1 worker."
      log "! Running Puma in cluster mode with a single worker is often a misconfiguration."
      log "! Consider running Puma in single-mode (workers = 0) in order to reduce memory overhead."
      log "! Set the `silence_single_worker_warning` option to silence this warning message."
    end

    # loops thru @workers, removing workers that exited, and calling
    # `#term` if needed
    def wait_workers
      @workers.reject! do |w|
        next false if w.pid.nil?
        begin
          if Process.wait(w.pid, Process::WNOHANG)
            true
          else
            w.term if w.term?
            nil
          end
        rescue Errno::ECHILD
          begin
            Process.kill(0, w.pid)
            # child still alive but has another parent (e.g., using fork_worker)
            w.term if w.term?
            false
          rescue Errno::ESRCH, Errno::EPERM
            true # child is already terminated
          end
        end
      end
    end

    # @version 5.0.0
    def timeout_workers
      @workers.each do |w|
        if !w.term? && w.ping_timeout <= Time.now
          details = if w.booted?
                      "(worker failed to check in within #{@options[:worker_timeout]} seconds)"
                    else
                      "(worker failed to boot within #{@options[:worker_boot_timeout]} seconds)"
                    end
          log "! Terminating timed out worker #{details}: #{w.pid}"
          w.kill
        end
      end
    end
  end
end
