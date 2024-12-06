require "pry"

require "guard"

module Guard
  module Commands
    class Pause
      def self.import
        Pry::Commands.create_command "pause" do
          group "Guard"
          description "Toggles the file listener."

          banner <<-BANNER
          Usage: pause

          Toggles the file listener on and off.

          When the file listener is paused, the default Guard Pry
          prompt will show the pause sign `[p]`.
          BANNER

          def process
            ::Guard.async_queue_add([:guard_pause])
          end
        end
      end
    end
  end
end
