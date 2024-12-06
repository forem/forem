# frozen_string_literal: true

module KnapsackPro
  module Runners
    module Queue
      class BaseRunner
        TERMINATION_SIGNALS = %w(HUP INT TERM ABRT QUIT USR1 USR2)

        @@terminate_process = false

        def self.run(args)
          raise NotImplementedError
        end

        def self.run_tests(runner, can_initialize_queue, args, exitstatus)
          raise NotImplementedError
        end

        def initialize(adapter_class)
          @allocator_builder = KnapsackPro::QueueAllocatorBuilder.new(adapter_class)
          @allocator = allocator_builder.allocator
          trap_signals
        end

        def test_file_paths(args)
          can_initialize_queue = args.fetch(:can_initialize_queue)
          executed_test_files = args.fetch(:executed_test_files)
          allocator.test_file_paths(can_initialize_queue, executed_test_files)
        end

        def test_dir
          allocator_builder.test_dir
        end

        private

        attr_reader :allocator_builder,
          :allocator

        def self.child_status
          $?
        end

        def self.handle_signal!
          raise 'Knapsack Pro process was terminated!' if @@terminate_process
        end

        def self.set_terminate_process
          @@terminate_process = true
        end

        def trap_signals
          TERMINATION_SIGNALS.each do |signal|
            Signal.trap(signal) {
              puts "#{signal} signal has been received. Terminating Knapsack Pro..."
              @@terminate_process = true
            }
          end
        end
      end
    end
  end
end
