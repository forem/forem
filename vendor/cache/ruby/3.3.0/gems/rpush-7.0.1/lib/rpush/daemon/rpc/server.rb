require 'socket'
require 'singleton'

module Rpush
  module Daemon
    module Rpc
      class Server
        include Singleton
        include Loggable
        include Reflectable

        def self.start
          instance.start
        end

        def self.stop
          instance.stop
        end

        def start
          @stop = false

          @thread = Thread.new(UNIXServer.open(Rpc.socket_path)) do |server|
            begin
              loop do
                socket = server.accept
                break if @stop
                read_loop(socket)
              end

              server.close
            rescue StandardError => e
              log_error(e)
            ensure
              File.unlink(Rpc.socket_path) if File.exist?(Rpc.socket_path)
            end
          end
        end

        def stop
          @stop = true
          UNIXSocket.new(Rpc.socket_path)
          @thread.join if @thread
        rescue StandardError => e
          log_error(e)
        end

        private

        def read_loop(socket)
          loop do
            line = socket.gets
            break unless line

            begin
              cmd, args = JSON.load(line)
              log_debug("[rpc:server] #{cmd.to_sym.inspect}, args: #{args.inspect}")
              response = process(cmd, args)
              socket.puts(JSON.dump(response))
            rescue StandardError => e
              log_error(e)
              reflect(:error, e)
            end
          end

          socket.close
        end

        def process(cmd, args) # rubocop:disable Lint/UnusedMethodArgument
          case cmd
          when 'status'
            status
          end
        end

        def status
          Rpush::Daemon::AppRunner.status
        end
      end
    end
  end
end
