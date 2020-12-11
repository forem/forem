require 'rspec/core/drb'

RSpec.describe RSpec::Core::DRbRunner, :isolated_directory => true, :isolated_home => true, :type => :drb, :unless => RUBY_PLATFORM == 'java' do
  let(:config) { RSpec::Core::Configuration.new }
  let(:out)    { StringIO.new }
  let(:err)    { StringIO.new }

  include_context "spec files"

  def runner(*args)
    RSpec::Core::DRbRunner.new(config_options(*args))
  end

  def config_options(*args)
    RSpec::Core::ConfigurationOptions.new(args)
  end

  context "without server running" do
    it "raises an error" do
      expect { runner.run(err, out) }.to raise_error(DRb::DRbConnError)
    end

    after { DRb.stop_service }
  end

  describe "--drb-port" do
    def with_RSPEC_DRB_set_to(val)
      with_env_vars('RSPEC_DRB' => val) { yield }
    end

    context "without RSPEC_DRB environment variable set" do
      it "defaults to 8989" do
        with_RSPEC_DRB_set_to(nil) do
          expect(runner.drb_port).to eq(8989)
        end
      end

      it "sets the DRb port" do
        with_RSPEC_DRB_set_to(nil) do
          expect(runner("--drb-port", "1234").drb_port).to eq(1234)
          expect(runner("--drb-port", "5678").drb_port).to eq(5678)
        end
      end
    end

    context "with RSPEC_DRB environment variable set" do
      context "without config variable set" do
        it "uses RSPEC_DRB value" do
          with_RSPEC_DRB_set_to('9000') do
            expect(runner.drb_port).to eq("9000")
          end
        end
      end

      context "and config variable set" do
        it "uses configured value" do
          with_RSPEC_DRB_set_to('9000') do
            expect(runner(*%w[--drb-port 5678]).drb_port).to eq(5678)
          end
        end
      end
    end
  end

  context "with server running", :slow do
    class SimpleDRbSpecServer
      def self.run(argv, err, out)
        options = RSpec::Core::ConfigurationOptions.new(argv)
        config  = RSpec::Core::Configuration.new
        RSpec.configuration = config
        RSpec::Core::Runner.new(options, config).run(err, out)
      end
    end

    before(:all) do
      @drb_port = '8990'
      DRb::start_service("druby://127.0.0.1:#{@drb_port}", SimpleDRbSpecServer)
    end

    after(:all) do
      DRb::stop_service
    end

    it "falls back to `druby://:0` when `druby://localhost:0` fails" do
      # see https://bugs.ruby-lang.org/issues/496 for background
      expect(::DRb).to receive(:start_service).with("druby://localhost:0").and_raise(SocketError)
      expect(::DRb).to receive(:start_service).with("druby://:0").and_call_original

      result = runner("--drb-port", @drb_port, passing_spec_filename).run(err, out)
      expect(result).to be(0)
    end

    it "returns 0 if spec passes" do
      result = runner("--drb-port", @drb_port, passing_spec_filename).run(err, out)
      expect(result).to be(0)
    end

    it "returns 1 if spec fails" do
      result = runner("--drb-port", @drb_port, failing_spec_filename).run(err, out)
      expect(result).to be(1)
    end

    it "outputs colorized text when running with --force-color option" do
      failure_symbol = "\e[#{RSpec::Core::Formatters::ConsoleCodes.console_code_for(:red)}mF"
      runner(failing_spec_filename, "--force-color", "--drb-port", @drb_port).run(err, out)
      expect(out.string).to include(failure_symbol)
    end
  end
end

RSpec.describe RSpec::Core::DRbOptions, :isolated_directory => true, :isolated_home => true do
  include ConfigOptionsHelper

  describe "DRB args" do
    def drb_argv_for(args)
      options = config_options_object(*args)
      RSpec::Core::DRbRunner.new(options, RSpec.configuration).drb_argv
    end

    def drb_filter_manager_for(args)
      configuration = RSpec::Core::Configuration.new
      RSpec::Core::DRbRunner.new(config_options_object(*args), configuration).drb_argv
      configuration.filter_manager
    end

    it "preserves extra arguments" do
      allow(File).to receive(:exist?) { false }
      expect(drb_argv_for(%w[ a --drb b --color c ])).to match_array %w[ --color a b c ]
    end

    %w(--color --force-color --no-color --fail-fast --profile --backtrace --tty).each do |option|
      it "includes #{option}" do
        expect(drb_argv_for([option])).to include(option)
      end
    end

    it "includes --failure-exit-code" do
      expect(drb_argv_for(%w[--failure-exit-code 2])).to include("--failure-exit-code", "2")
    end

    it "includes --options" do
      expect(drb_argv_for(%w[--options custom.opts])).to include("--options", "custom.opts")
    end

    it "includes --order" do
      expect(drb_argv_for(%w[--order random])).to include('--order', 'random')
    end

    context "with --example" do
      it "includes --example" do
        expect(drb_argv_for(%w[--example foo])).to include("--example", "foo")
      end

      it "unescapes characters which were escaped upon storing --example originally" do
        expect(drb_argv_for(["--example", "foo\\ bar"])).to include("--example", "foo bar")
      end
    end

    context "with tags" do
      it "includes the inclusion tags" do
        expect(drb_argv_for ["--tag", "tag"]).to eq(["--tag", "tag"])
      end

      it "includes the inclusion tags with values" do
        expect(drb_argv_for ["--tag", "tag:foo"]).to eq(["--tag", "tag:foo"])
      end

      it "leaves inclusion tags intact" do
        rules = drb_filter_manager_for(%w[ --tag tag ]).inclusions.rules
        expect(rules).to eq( {:tag=>true} )
      end

      it "leaves inclusion tags with values intact" do
        rules = drb_filter_manager_for(%w[ --tag tag:foo ]).inclusions.rules
        expect(rules).to eq( {:tag=>'foo'} )
      end

      it "includes the exclusion tags" do
        expect(drb_argv_for ["--tag", "~tag"]).to eq(["--tag", "~tag"])
      end

      it "includes the exclusion tags with values" do
        expect(drb_argv_for ["--tag", "~tag:foo"]).to eq(["--tag", "~tag:foo"])
      end

      it "leaves exclusion tags intact" do
        rules = drb_filter_manager_for(%w[ --tag ~tag ]).exclusions.rules
        expect(rules).to eq( {:tag => true} )
      end

      it "leaves exclusion tags with values intact" do
        rules = drb_filter_manager_for(%w[ --tag ~tag:foo ]).exclusions.rules
        expect(rules).to eq( {:tag => 'foo'} )
      end
    end

    context "with formatters" do
      it "includes the formatters" do
        expect(drb_argv_for ["--format", "d"]).to eq(["--format", "d"])
      end

      it "leaves formatters intact" do
        coo = config_options_object("--format", "d")
        RSpec::Core::DRbRunner.new(coo, RSpec::Core::Configuration.new).drb_argv
        expect(coo.options[:formatters]).to eq([["d"]])
      end

      it "leaves output intact" do
        coo = config_options_object("--format", "p", "--out", "foo.txt", "--format", "d")
        RSpec::Core::DRbRunner.new(coo, RSpec::Core::Configuration.new).drb_argv
        expect(coo.options[:formatters]).to eq([["p","foo.txt"],["d"]])
      end
    end

    context "with --out" do
      it "combines with formatters" do
        argv = drb_argv_for(%w[--format h --out report.html])
        expect(argv).to  eq(%w[--format h --out report.html])
      end
    end

    context "with -I libs" do
      it "includes -I" do
        expect(drb_argv_for(%w[-I a_dir])).to eq(%w[-I a_dir])
      end

      it "includes multiple paths" do
        argv = drb_argv_for(%w[-I dir_1 -I dir_2 -I dir_3])
        expect(argv).to  eq(%w[-I dir_1 -I dir_2 -I dir_3])
      end
    end

    context "with --require" do
      it "includes --require" do
        expect(drb_argv_for(%w[--require a_path])).to eq(%w[--require a_path])
      end

      it "includes multiple paths" do
        argv = drb_argv_for(%w[--require dir/ --require file.rb])
        expect(argv).to  eq(%w[--require dir/ --require file.rb])
      end
    end

    context "--drb specified in ARGV" do
      it "renders all the original arguments except --drb" do
        argv = drb_argv_for(%w[ --drb --color --format s --example pattern
                                --profile --backtrace -I
                                path/a -I path/b --require path/c --require
                                path/d])
        expect(argv).to eq(%w[ --color --profile --backtrace --example pattern --format s -I path/a -I path/b --require path/c --require path/d])
      end
    end

    context "--drb specified in the options file" do
      it "renders all the original arguments except --drb" do
        File.open("./.rspec", "w") {|f| f << "--drb --color"}
        drb_argv = drb_argv_for(%w[ --tty --format s --example pattern --profile --backtrace ])
        expect(drb_argv).to eq(%w[ --color --profile --backtrace --tty --example pattern --format s])
      end
    end

    context "--drb specified in ARGV and the options file" do
      it "renders all the original arguments except --drb" do
        File.open("./.rspec", "w") {|f| f << "--drb --color"}
        argv = drb_argv_for(%w[ --drb --format s --example pattern --profile --backtrace])
        expect(argv).to eq(%w[ --color --profile --backtrace --example pattern --format s])
      end
    end

    context "--drb specified in ARGV and in as ARGV-specified --options file" do
      it "renders all the original arguments except --drb and --options" do
        File.open("./.rspec", "w") {|f| f << "--drb --color"}
        argv = drb_argv_for(%w[ --drb --format s --example pattern --profile --backtrace])
        expect(argv).to eq(%w[ --color --profile --backtrace --example pattern --format s ])
      end
    end

    describe "--drb, -X" do
      it "does not send --drb back to the parser after parsing options" do
        expect(drb_argv_for(%w[--drb --color])).not_to include("--drb")
      end
    end
  end
end
