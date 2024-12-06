require "pry"

require "guard/notifier"

module Guard
  module Commands
    class Notification
      def self.import
        Pry::Commands.create_command "notification" do
          group "Guard"
          description "Toggles the notifications."

          banner <<-BANNER
          Usage: notification

          Toggles the notifications on and off.
          BANNER

          def process
            Notifier.toggle
          end
        end
      end
    end
  end
end
