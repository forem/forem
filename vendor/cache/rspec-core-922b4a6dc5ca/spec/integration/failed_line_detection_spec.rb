require 'support/aruba_support'

RSpec.describe 'Failed line detection' do
  include_context "aruba support"
  before { setup_aruba }

  it "finds the source of a failure in a spec file that is defined at the current directory instead of in the normal `spec` subdir" do
    write_file "the_spec.rb", "
      RSpec.describe do
        it 'fails via expect' do
          expect(1).to eq(2)
        end
      end
    "

    run_command "the_spec.rb"
    expect(last_cmd_stdout).to include("expect(1).to eq(2)")
  end

  it "finds the source of a failure in a spec file loaded by running `ruby file` rather than loaded directly by RSpec" do
    write_file "passing_spec.rb", "
      RSpec.describe do
        example { }
      end
    "

    write_file "failing_spec.rb", "
      RSpec.describe do
        it 'fails via expect' do
          expect(1).to eq(2)
        end
      end
    "

    file = cd('.') { "#{Dir.pwd}/failing_spec.rb" }
    load file
    run_command "passing_spec.rb"

    expect(last_cmd_stdout).to include("expect(1).to eq(2)")
  end

  it "finds the direct source of failure in any lib, app or spec file, and allows the user to configure what is considered a project source dir" do
    write_file "lib/lib_mod.rb", "
      module LibMod
        def self.trigger_failure
          raise 'LibMod failure'
        end
      end
    "

    write_file "app/app_mod.rb", "
      module AppMod
        def self.trigger_failure
          raise 'AppMod failure'
        end
      end
    "

    write_file "spec/support/spec_support.rb", "
      module SpecSupport
        def self.trigger_failure
          raise 'SpecSupport failure'
        end
      end
    "

    write_file "spec/default_config_spec.rb", "
      require './lib/lib_mod'
      require './spec/support/spec_support'
      require './app/app_mod'

      RSpec.describe do
        example('1') { LibMod.trigger_failure }
        example('2') { AppMod.trigger_failure }
        example('3') { SpecSupport.trigger_failure }
      end
    "

    run_command "./spec/default_config_spec.rb"

    expect(last_cmd_stdout).to include("raise 'LibMod failure'").
                           and include("raise 'AppMod failure'").
                           and include("raise 'SpecSupport failure'").
                           and exclude("AppMod.trigger_failure")

    write_file "spec/change_config_spec.rb", "
      require './app/app_mod'

      RSpec.configure do |c|
        c.project_source_dirs = %w[ lib spec ]
      end

      RSpec.describe do
        example('1') { AppMod.trigger_failure }
      end
    "

    run_command "./spec/change_config_spec.rb"

    expect(last_cmd_stdout).to include("AppMod.trigger_failure").
                           and exclude("raise 'AppMod failure'")
  end

  it "finds the callsite of a method provided by a gem that fails (rather than the line in the gem)" do
    write_file "vendor/gems/assertions/lib/assertions.rb", "
      module Assertions
        AssertionFailed = Class.new(StandardError)

        def assert(value, msg)
          raise(AssertionFailed, msg) unless value
        end
      end
    "

    write_file "spec/unit/the_spec.rb", "
      require './vendor/gems/assertions/lib/assertions'

      RSpec.describe do
        include Assertions

        it 'fails via assert' do
          assert false, 'failed assertion'
        end

        it 'fails via expect' do
          expect(1).to eq(2)
        end
      end
    "

    run_command ""

    expect(last_cmd_stdout).to include("assert false, 'failed assertion'").
                           and include("expect(1).to eq(2)").
                           and exclude("raise(AssertionFailed, msg)")
  end

  it "falls back to finding a line in a gem when there are no backtrace lines in the app, lib or spec directories" do
    write_file "vendor/gems/before_failure/lib/before_failure.rb", "
      RSpec.configure do |c|
        c.before { raise 'before failure!' }
      end
    "

    write_file "spec/unit/the_spec.rb", "
      require './vendor/gems/before_failure/lib/before_failure'

      RSpec.describe do
        example('1') { }
      end
    "

    run_command ""

    expect(last_cmd_stdout).to include("c.before { raise 'before failure!' }").
                           and exclude("Unable to find matching line from backtrace")
  end
end
