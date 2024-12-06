# encoding: UTF-8

module Rpush
  module Daemon
    class AppRunner
      extend Reflectable
      include Reflectable
      include Loggable
      extend Loggable
      include StringHelpers
      extend StringHelpers

      @runners = {}

      def self.enqueue(notifications)
        notifications.group_by(&:app_id).each do |app_id, group|
          start_app_with_id(app_id) unless @runners[app_id]
          @runners[app_id].enqueue(group) if @runners[app_id]
        end

        ProcTitle.update
      end

      def self.start_app_with_id(app_id)
        start_app(Rpush::Daemon.store.app(app_id))
      end

      def self.start_app(app)
        Rpush.logger.info("[#{app.name}] Starting #{pluralize(app.connections, 'dispatcher')}... ", true)
        runner = @runners[app.id] = new(app)
        runner.start_dispatchers
        puts Rainbow('✔').green if Rpush.config.foreground && Rpush.config.foreground_logging
        runner.start_loops
      rescue StandardError => e
        @runners.delete(app.id)
        Rpush.logger.error("[#{app.name}] Exception raised during startup. Notifications will not be delivered for this app.")
        Rpush.logger.error(e)
        reflect(:error, e)
      end

      def self.stop_app(app_id)
        runner = @runners.delete(app_id)
        if runner
          runner.stop
          log_info("[#{runner.app.name}] Stopped.")
        end
      end

      def self.app_with_id(app_id)
        @runners[app_id].app
      end

      def self.app_running?(app)
        @runners.key?(app.id)
      end

      def self.app_ids
        @runners.keys
      end

      def self.stop
        @runners.values.map(&:stop)
        @runners.clear
      end

      def self.total_dispatchers
        @runners.values.sum(&:num_dispatcher_loops)
      end

      def self.total_queued
        @runners.values.sum(&:queue_size)
      end

      def self.num_dispatchers_for_app(app)
        runner = @runners[app.id]
        runner ? runner.num_dispatcher_loops : 0
      end

      def self.decrement_dispatchers(app, num)
        @runners[app.id].decrement_dispatchers(num)
      end

      def self.increment_dispatchers(app, num)
        @runners[app.id].increment_dispatchers(num)
      end

      def self.status
        { app_runners: @runners.values.map(&:status) }
      end

      attr_reader :app
      delegate :size, to: :queue, prefix: true

      def initialize(app)
        @app = app
        @loops = []
        @dispatcher_loops = []
      end

      def start_dispatchers
        app.connections.times { @dispatcher_loops.push(new_dispatcher_loop) }
      end

      def start_loops
        @loops = service.loop_instances(@app)
        @loops.map(&:start)
      end

      def stop
        wait_until_idle
        stop_dispatcher_loops
        stop_loops
      end

      def wait_until_idle
        sleep 0.5 while queue.size > 0
      end

      def enqueue(notifications)
        if service.batch_deliveries?
          batch_size = (notifications.size / num_dispatcher_loops.to_f).ceil
          notifications.in_groups_of(batch_size, false).each do |batch_notifications|
            batch = Batch.new(batch_notifications)
            queue.push(QueuePayload.new(batch))
          end
        else
          batch = Batch.new(notifications)
          notifications.each do |notification|
            queue.push(QueuePayload.new(batch, notification))
            reflect(:notification_enqueued, notification)
          end
        end
      end

      def decrement_dispatchers(num)
        num.times { @dispatcher_loops.pop.stop }
      end

      def increment_dispatchers(num)
        num.times { @dispatcher_loops.push(new_dispatcher_loop) }
      end

      def status
        dispatcher_details = {}

        @dispatcher_loops.each_with_index do |dispatcher_loop, i|
          dispatcher_details[i] = {
            started_at: dispatcher_loop.started_at.iso8601,
            dispatched: dispatcher_loop.dispatch_count,
            thread_status: dispatcher_loop.thread_status
          }
        end

        { app_name: @app.name, dispatchers: dispatcher_details, queued: queue_size }
      end

      def num_dispatcher_loops
        @dispatcher_loops.size
      end

      private

      def stop_loops
        @loops.map(&:stop)
        @loops = []
      end

      def stop_dispatcher_loops
        @dispatcher_loops.map(&:stop)
        @dispatcher_loops.clear
      end

      def new_dispatcher_loop
        dispatcher = service.new_dispatcher(@app)
        dispatcher_loop = Rpush::Daemon::DispatcherLoop.new(queue, dispatcher)
        dispatcher_loop.start
        dispatcher_loop
      end

      def service
        return @service if defined? @service
        @service = "Rpush::Daemon::#{@app.service_name.camelize}".constantize
      end

      def queue
        @queue ||= Queue.new
      end
    end
  end
end
