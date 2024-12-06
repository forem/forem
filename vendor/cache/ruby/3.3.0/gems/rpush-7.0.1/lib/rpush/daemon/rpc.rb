module Rpush
  module Daemon
    module Rpc
      def self.socket_path(pid = Process.pid)
        "/tmp/rpush.#{pid}.sock"
      end
    end
  end
end
