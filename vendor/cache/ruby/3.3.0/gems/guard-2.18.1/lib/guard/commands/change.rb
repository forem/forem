require "pry"

require "guard"

module Guard
  module Commands
    class Change
      def self.import
        Pry::Commands.create_command "change" do
          group "Guard"
          description "Trigger a file change."

          banner <<-BANNER
          Usage: change <file> <other_file>

          Pass the given files to the Guard plugin `run_on_changes` action.
          BANNER

          def process(*files)
            if files.empty?
              output.puts "Please specify a file."
              return
            end

            Guard.async_queue_add(modified: files, added: [], removed: [])
          end
        end
      end
    end
  end
end
