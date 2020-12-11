module RSpec::Core
  RSpec.describe BacktraceFormatter do
    def make_backtrace_formatter(exclusion_patterns=nil, inclusion_patterns=nil)
      BacktraceFormatter.new.tap do |bc|
        bc.exclusion_patterns = exclusion_patterns if exclusion_patterns
        bc.inclusion_patterns = inclusion_patterns if inclusion_patterns
      end
    end

    describe "defaults" do
      it "excludes rspec files" do
        expect(make_backtrace_formatter.exclude?("/lib/rspec/core.rb")).to be true
        expect(make_backtrace_formatter.exclude?("/lib/rspec/core/foo.rb")).to be true
        expect(make_backtrace_formatter.exclude?("/lib/rspec/expectations/foo.rb")).to be true
        expect(make_backtrace_formatter.exclude?("/lib/rspec/matchers/foo.rb")).to be true
        expect(make_backtrace_formatter.exclude?("/lib/rspec/mocks/foo.rb")).to be true
        expect(make_backtrace_formatter.exclude?("/lib/rspec/support/foo.rb")).to be true
      end

      it "excludes the rspec binary, even when rspec-core has installed as a bundler :git dependency" do
        expect(make_backtrace_formatter.exclude?("exe/rspec")).to be true
      end

      it "excludes java files (for JRuby)", :if => (RUBY_PLATFORM == 'java')  do
        expect(make_backtrace_formatter.exclude?("org/jruby/RubyArray.java:2336")).to be true
      end

      it "includes files in projects containing 'gems' in the name" do
        expect(make_backtrace_formatter.exclude?('code/my-gems-plugin/lib/plugin.rb')).to be false
      end

      it "includes something in the current working directory" do
        expect(make_backtrace_formatter.exclude?("#{Dir.getwd}/arbitrary")).to be false
      end

      it 'allows users to exclude their bundler vendor directory' do
        formatter = make_backtrace_formatter([%r{/vendor/bundle/}])
        vendored_gem_line = File.join(Dir.getwd, "vendor/bundle/gems/mygem-4.1.6/lib/my_gem:241")
        expect(formatter.exclude? vendored_gem_line).to be true
      end

      context "when the exclusion list has been replaced" do
        it "includes a line that the default patterns exclude" do
          formatter = make_backtrace_formatter
          expect {
            formatter = make_backtrace_formatter([/spec_helper/])
          }.to change { formatter.exclude? "/path/to/lib/rspec/expectations/foo.rb" }.from(true).to(false)
        end
      end

      context "when the current working directory includes `gems` in the name" do
        around(:example) do |ex|
          Dir.mktmpdir do |tmp_dir|
            dir = File.join(tmp_dir, "gems")
            Dir.mkdir(dir)
            Dir.chdir(dir, &ex)
          end
        end

        it "includes something in the current working directory" do
          expect(make_backtrace_formatter.exclude?("#{Dir.getwd}/arbitrary")).to be false
        end
      end
    end

    describe "#filter_gem" do
      shared_examples_for "filtering a gem" do |gem_name, path|
        it 'filters backtrace lines for the named gem' do
          formatter = BacktraceFormatter.new
          line      = File.join(path, "lib", "foo.rb:13")

          expect {
            formatter.filter_gem gem_name
          }.to change { formatter.exclude?(line) }.from(false).to(true)
        end
      end

      context "for a gem installed globally as a system gem" do
        include_examples "filtering a gem", "foo",
          "/Users/myron/.gem/ruby/2.1.1/gems/foo-1.6.3.1"
      end

      context "for a gem installed in a vendored bundler path" do
        include_examples "filtering a gem", "foo",
          "/Users/myron/code/my_project/bundle/ruby/2.1.0/gems/foo-0.3.6"
      end

      context "for a gem installed by bundler as a :git dependency" do
        include_examples "filtering a gem", "foo",
          "/Users/myron/code/my_project/bundle/ruby/2.1.0/bundler/gems/foo-2b826653e1f5"
      end

      context "for a gem sourced from a local path" do
        include_examples "filtering a gem", "foo", "/Users/myron/code/foo"
      end

      context "when vendored under the working directory" do
        include_examples "filtering a gem", "foo",
          File.join(Dir.getwd, "bundle/ruby/2.1.0/bundler/gems/foo-0.3.6")
      end
    end

    describe "#format_backtrace" do
      it "excludes lines from rspec libs by default" do
        backtrace = [
          "/path/to/rspec-expectations/lib/rspec/expectations/foo.rb:37",
          "/path/to/rspec-expectations/lib/rspec/matchers/foo.rb:37",
          "./my_spec.rb:5",
          "/path/to/rspec-mocks/lib/rspec/mocks/foo.rb:37",
          "/path/to/rspec-core/lib/rspec/core/foo.rb:37"
        ]

        expect(BacktraceFormatter.new.format_backtrace(backtrace)).to eq(["./my_spec.rb:5"])
      end

      it "excludes lines from bundler by default, since Bundler 1.12 now includes its stackframes in all stacktraces when you `bundle exec`" do
        bundler_trace = [
          "/some/other/file.rb:13",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/cli/exec.rb:63:in `load'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/cli/exec.rb:63:in `kernel_load'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/cli/exec.rb:24:in `run'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/cli.rb:304:in `exec'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/vendor/thor/lib/thor/command.rb:27:in `run'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/vendor/thor/lib/thor/invocation.rb:126:in `invoke_command'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/vendor/thor/lib/thor.rb:359:in `dispatch'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/vendor/thor/lib/thor/base.rb:440:in `start'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/cli.rb:11:in `start'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/exe/bundle:27:in `block in <top (required)>'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/lib/bundler/friendly_errors.rb:98:in `with_friendly_errors'",
          "/Users/myron/.gem/ruby/2.3.0/gems/bundler-1.12.3/exe/bundle:19:in `<top (required)>'",
          "/Users/myron/.gem/ruby/2.3.0/bin/bundle:23:in `load'",
          "/Users/myron/.gem/ruby/2.3.0/bin/bundle:23:in `<main>'"
        ]

        expect(BacktraceFormatter.new.format_backtrace(bundler_trace)).to eq ["/some/other/file.rb:13"]
      end

      context "when every line is filtered out" do
        let(:backtrace) do
          [
            "/path/to/rspec-expectations/lib/rspec/expectations/foo.rb:37",
            "/path/to/rspec-expectations/lib/rspec/matchers/foo.rb:37",
            "/path/to/rspec-mocks/lib/rspec/mocks/foo.rb:37",
            "/path/to/rspec-core/lib/rspec/core/foo.rb:37"
          ]
        end

        it "includes full backtrace" do
          expect(BacktraceFormatter.new.format_backtrace(self.backtrace).take(4)).to eq self.backtrace
        end

        it "adds a message explaining everything was filtered" do
          expect(BacktraceFormatter.new.format_backtrace(self.backtrace).drop(4).join).to match(/Showing full backtrace/)
        end
      end

      describe "for an empty backtrace" do
        it "does not add the explanatory message about backtrace filtering" do
          formatter = BacktraceFormatter.new
          expect(formatter.format_backtrace([])).to eq([])
        end
      end

      describe "for a `nil` backtrace (since exceptions can have no backtrace!)" do
        it 'returns a blank array, with no explanatory message' do
          exception = Exception.new
          expect(exception.backtrace).to be_nil

          formatter = BacktraceFormatter.new
          expect(formatter.format_backtrace(exception.backtrace)).to eq([])
        end
      end

      context "when rspec is installed in the current working directory" do
        it "excludes lines from rspec libs by default", :unless => RSpec::Support::OS.windows? do
          backtrace = [
            "#{Dir.getwd}/.bundle/path/to/rspec-expectations/lib/rspec/expectations/foo.rb:37",
            "#{Dir.getwd}/.bundle/path/to/rspec-expectations/lib/rspec/matchers/foo.rb:37",
            "#{Dir.getwd}/my_spec.rb:5",
            "#{Dir.getwd}/.bundle/path/to/rspec-mocks/lib/rspec/mocks/foo.rb:37",
            "#{Dir.getwd}/.bundle/path/to/rspec-core/lib/rspec/core/foo.rb:37"
          ]

          expect(BacktraceFormatter.new.format_backtrace(backtrace)).to eq(["./my_spec.rb:5"])
        end
      end
    end

    describe "#full_backtrace=true" do
      it "sets full_backtrace true" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        formatter.full_backtrace = true
        expect(formatter.full_backtrace?).to be true
      end

      it "preserves exclusion and inclusion patterns" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        formatter.full_backtrace = true
        expect(formatter.exclusion_patterns).to eq [/discard/]
        expect(formatter.inclusion_patterns).to eq [/keep/]
      end

      it "keeps all lines, even those that match exclusions" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        formatter.full_backtrace = true
        expect(formatter.exclude? "discard").to be false
      end
    end

    describe "#full_backtrace=false (after it was true)" do
      it "sets full_backtrace false" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        formatter.full_backtrace = true
        formatter.full_backtrace = false
        expect(formatter.full_backtrace?).to be false
      end

      it "preserves exclusion and inclusion patterns" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        formatter.full_backtrace = true
        formatter.full_backtrace = false
        expect(formatter.exclusion_patterns).to eq [/discard/]
        expect(formatter.inclusion_patterns).to eq [/keep/]
      end

      it "excludes lines that match exclusions" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        formatter.full_backtrace = true
        formatter.full_backtrace = false
        expect(formatter.exclude? "discard").to be true
      end
    end

    describe "#backtrace_line" do
      let(:formatter) { BacktraceFormatter.new }

      it "trims current working directory" do
        expect(self.formatter.__send__(:backtrace_line, File.expand_path(__FILE__))).to eq("./spec/rspec/core/backtrace_formatter_spec.rb")
      end

      it "preserves the original line" do
        original_line = File.expand_path(__FILE__)
        self.formatter.__send__(:backtrace_line, original_line)
        expect(original_line).to eq(File.expand_path(__FILE__))
      end

      it "deals gracefully with a security error" do
        Metadata.instance_eval { @relative_path_regex = nil }
        with_safe_set_to_level_that_triggers_security_errors do
          self.formatter.__send__(:backtrace_line, __FILE__)
          # on some rubies, this doesn't raise a SecurityError; this test just
          # assures that if it *does* raise an error, the error is caught inside
        end
      end
    end

    context "when the current directory matches one of the default exclusion patterns" do
      include_context "isolated directory"

      around do |ex|
        FileUtils.mkdir_p("bin")
        Dir.chdir("./bin", &ex)
      end

      let(:line) { File.join(Dir.getwd, "foo.rb:13") }

      it 'does not exclude lines from files in the current directory' do
        expect(make_backtrace_formatter.exclude? self.line).to be false
      end

      context "with inclusion_patterns cleared" do
        it 'excludes lines from files in the current directory' do
          formatter = make_backtrace_formatter
          formatter.inclusion_patterns.clear

          expect(formatter.exclude? self.line).to be true
        end
      end
    end

    context "with no patterns" do
      it "keeps all lines" do
        lines = ["/tmp/a_file", "some_random_text", "hello\330\271!"]
        formatter = make_backtrace_formatter([], [])
        expect(lines.all? {|line| formatter.exclude? line}).to be false
      end

      it "is considered a full backtrace" do
        expect(make_backtrace_formatter([], []).full_backtrace?).to be true
      end
    end

    context "with an exclusion pattern but no inclusion patterns" do
      it "excludes lines that match the exclusion pattern" do
        formatter = make_backtrace_formatter([/discard/],[])
        expect(formatter.exclude? "discard me").to be true
      end

      it "keeps lines that do not match the exclusion pattern" do
        formatter = make_backtrace_formatter([/discard/],[])
        expect(formatter.exclude? "apple").to be false
      end

      it "is considered a partial backtrace" do
        formatter = make_backtrace_formatter([/discard/],[])
        expect(formatter.full_backtrace?).to be false
      end
    end

    context "with an exclusion pattern and an inclusion pattern" do
      it "excludes lines that match the exclusion pattern but not the inclusion pattern" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        expect(formatter.exclude? "discard").to be true
      end

      it "keeps lines that match both patterns" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        expect(formatter.exclude? "discard/keep").to be false
      end

      it "keeps lines that match neither pattern" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        expect(formatter.exclude? "fish").to be false
      end

      it "is considered a partial backtrace" do
        formatter = make_backtrace_formatter([/discard/],[/keep/])
        expect(formatter.full_backtrace?).to be false
      end
    end
  end
end
