require "guard/jobs/base"
require "guard/ui"

module Guard
  module Jobs
    class Sleep < Base
      def foreground
        UI.debug "Guards jobs done. Sleeping..."
        sleep
        UI.debug "Sleep interrupted by events."
        :stopped
      rescue Interrupt
        UI.debug "Sleep interrupted by user."
        :exit
      end

      def background
        Thread.main.wakeup
      end

      def handle_interrupt
        Thread.main.raise Interrupt
      end
    end
  end
end
