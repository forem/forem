require 'naught/null_class_builder/command'

module Naught
  class NullClassBuilder
    module Commands
      class Pebble < ::Naught::NullClassBuilder::Command
        def initialize(builder, output = $stdout)
          @builder = builder
          @output = output
        end

        def call
          defer do |subject|
            subject.module_exec(@output) do |output|
              define_method(:method_missing) do |method_name, *args|
                pretty_args = args.collect(&:inspect).join(', ').tr("\"", "'")
                output.puts "#{method_name}(#{pretty_args}) from #{parse_caller}"
                self
              end

              def parse_caller
                caller = Kernel.caller(2).first
                method_name = caller.match(/\`([\w\s]+(\(\d+\s\w+\))?[\w\s]*)/)
                method_name ? method_name[1] : caller
              end
              private :parse_caller
            end
          end
        end
      end
    end
  end
end
