module Rpush
  module Daemon
    class SignalHandler
      extend Loggable

      class << self
        attr_reader :thread
      end

      def self.start
        return unless trap_signals?

        read_io, @write_io = IO.pipe
        start_handler(read_io)
        %w(INT TERM HUP USR2).each do |signal|
          Signal.trap(signal) { @write_io.puts(signal) }
        end
      end

      def self.stop
        @write_io.puts('break') if @write_io
        @thread.join if @thread
      rescue StandardError => e
        log_error(e)
        reflect(:error, e)
      ensure
        @thread = nil
      end

      def self.start_handler(read_io)
        @thread = Thread.new do
          while readable_io = IO.select([read_io]) # rubocop:disable Lint/AssignmentInCondition
            signal = readable_io.first[0].gets.strip

            begin
              case signal
              when 'HUP'
                handle_hup
              when 'USR2'
                handle_usr2
              when 'INT', 'TERM'
                Thread.new { Rpush::Daemon.shutdown }
                break
              when 'break'
                break
              else
                Rpush.logger.error("Unhandled signal: #{signal}")
              end
            rescue StandardError => e
              Rpush.logger.error("Error raised when handling signal '#{signal}'")
              Rpush.logger.error(e)
            end
          end
        end
      end

      def self.handle_hup
        Rpush.logger.reopen
        Rpush.logger.info('Received HUP signal.')
        Rpush::Daemon.store.reopen_log
        Synchronizer.sync
        Feeder.wakeup
      end

      def self.handle_usr2
        Rpush.logger.info('Received USR2 signal.')
        AppRunner.debug
      end

      def self.trap_signals?
        !Rpush.config.embedded
      end
    end
  end
end
