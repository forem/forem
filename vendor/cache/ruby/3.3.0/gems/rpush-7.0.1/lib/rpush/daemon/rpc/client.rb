module Rpush
  module Daemon
    module Rpc
      class Client
        def initialize(pid)
          @socket = UNIXSocket.open(Rpc.socket_path(pid))
        end

        def status
          call(:status)
        end

        def close
          @socket.close
        rescue StandardError # rubocop:disable Lint/HandleExceptions
        end

        private

        def call(cmd, args = {})
          @socket.puts(JSON.dump([cmd, args]))
          JSON.parse(@socket.gets)
        end
      end
    end
  end
end
