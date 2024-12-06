module Rpush
  module Daemon
    class ProcTitle
      def self.update
        return if Rpush.config.embedded || Rpush.config.push
        Process.respond_to?(:setproctitle) ? Process.setproctitle(proc_title) : $0 = proc_title
      end

      def self.proc_title
        total_dispatchers = AppRunner.total_dispatchers
        dispatchers_str = total_dispatchers == 1 ? 'dispatcher' : 'dispatchers'
        total_queued = AppRunner.total_queued
        format("rpush | %d queued | %d %s", total_queued, total_dispatchers, dispatchers_str)
      end
    end
  end
end
