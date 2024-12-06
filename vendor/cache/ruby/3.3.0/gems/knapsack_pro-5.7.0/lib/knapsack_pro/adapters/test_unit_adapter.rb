# frozen_string_literal: true

module KnapsackPro
  module Adapters
    class TestUnitAdapter < BaseAdapter
      TEST_DIR_PATTERN = 'test/**{,/*/**}/*_test.rb'
      @@parent_of_test_dir = nil

      def self.test_path(obj)
        full_test_path = nil
        found_valid_test_file_path = false

        obj.tests.each do |test_obj|
          method = test_obj.method_name
          full_test_path = test_obj.method(method).source_location.first
          # if we find a test file path that is a valid test file path within test suite directory
          # then break to stop looking further.
          # If we won't find a valid test file path then the last found path will be used as full_test_path
          # For instance if test file contains only shared examples then it's not possible to properly detect test file path
          # so the wrong path can be used like:
          # /Users/artur/.rvm/gems/ruby-2.6.5/gems/shared_should-0.10.0/lib/shared_should/shared_context.rb
          if full_test_path.include?(@@parent_of_test_dir)
            found_valid_test_file_path = true
            break
          end
        end

        unless found_valid_test_file_path
          KnapsackPro.logger.warn("cannot detect a valid test file path. Probably the test file contains only shared examples. Please add test cases to your test file. Read more at #{KnapsackPro::Urls::TEST_UNIT__TEST_FILE_PATH_DETECTION}")
          KnapsackPro.logger.warn("See test file for #{obj.inspect}")
        end

        parent_of_test_dir_regexp = Regexp.new("^#{@@parent_of_test_dir}")
        test_path = full_test_path.gsub(parent_of_test_dir_regexp, '.')
        # test_path will look like ./test/dir/unit_test.rb
        test_path
      end

      # Overrides the method from unit-test gem
      # https://github.com/test-unit/test-unit/blob/master/lib/test/unit/testsuite.rb
      module BindTimeTrackerTestUnitPlugin
        def run_startup(result)
          return if @test_case.nil?
          KnapsackPro.tracker.current_test_path = KnapsackPro::Adapters::TestUnitAdapter.test_path(self)
          KnapsackPro.tracker.start_timer
          return if !@test_case.respond_to?(:startup)
          begin
            @test_case.startup
          rescue Exception
            raise unless handle_exception($!, result)
          end
        end

        def run_shutdown(result)
          return if @test_case.nil?
          KnapsackPro.tracker.stop_timer
          return if !@test_case.respond_to?(:shutdown)
          begin
            @test_case.shutdown
          rescue Exception
            raise unless handle_exception($!, result)
          end
        end
      end

      def bind_time_tracker
        ::Test::Unit::TestSuite.send(:prepend, BindTimeTrackerTestUnitPlugin)

        add_post_run_callback do
          KnapsackPro.logger.debug(KnapsackPro::Presenter.global_time)
        end
      end

      def bind_save_report
        add_post_run_callback do
          KnapsackPro::Report.save
        end
      end

      def set_test_helper_path(file_path)
        test_dir_path = File.dirname(file_path)
        @@parent_of_test_dir = File.expand_path('../', test_dir_path)
      end

      private

      def add_post_run_callback(&block)
        ::Test::Unit.at_exit do
          block.call
        end
      end
    end
  end
end
