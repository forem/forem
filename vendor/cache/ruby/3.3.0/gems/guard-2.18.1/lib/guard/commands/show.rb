require "pry"

module Guard
  module Commands
    class Show
      def self.import
        Pry::Commands.create_command "show" do
          group "Guard"
          description "Show all Guard plugins."

          banner <<-BANNER
          Usage: show

          Show all defined Guard plugins and their options.
          BANNER

          def process
            Guard.async_queue_add([:guard_show])
          end
        end
      end
    end
  end
end
