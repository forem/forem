require 'spec_helper'
require 'fileutils'
require 'rspec/support/caller_filter'

module RSpec
  describe CallerFilter do
    it 'can receive skip_frames and increment arguments' do
      expect(RSpec::CallerFilter.first_non_rspec_line(1, 5)).to include("#{__FILE__}:#{__LINE__}")
    end

    it 'returns the immediate caller when called from a spec' do
      expect(RSpec::CallerFilter.first_non_rspec_line).to include("#{__FILE__}:#{__LINE__}")
    end

    describe "the filtering regex" do
      def ruby_files_in_lib(lib)
        # http://rubular.com/r/HYpUMftlG2
        path = $LOAD_PATH.find { |p| p.match(/\/rspec-#{lib}(-[a-f0-9]+)?\/lib/) }

        Dir["#{path}/**/*.rb"].sort.tap do |files|
          # Just a sanity check...
          expect(files.count).to be > 5
        end
      end

      def unmatched_from(files)
        files.reject { |file| file.match(CallerFilter::IGNORE_REGEX) }
      end

      %w[ core mocks expectations support ].each do |lib|
        it "matches all ruby files in rspec-#{lib}" do
          files = ruby_files_in_lib(lib)
          expect(unmatched_from files).to eq([])
        end
      end

      it "does not match other ruby files" do
        files = %w[
          /path/to/lib/rspec/some-extension/foo.rb
          /path/to/spec/rspec/core/some_spec.rb
        ]

        expect(unmatched_from files).to eq(files)
      end

      def in_rspec_support_lib(name)
        root = File.expand_path("../../../../lib/rspec/support", __FILE__)
        dir = "#{root}/#{name}"
        FileUtils.mkdir(dir)
        yield dir
      ensure
        FileUtils.rm_rf(dir)
      end

      it 'does not match rubygems lines from `require` statements' do
        with_isolated_stderr do
          require 'rubygems' # ensure rubygems is laoded
        end

        in_rspec_support_lib("test_dir") do |dir|
          File.open("#{dir}/file.rb", "w") do |file|
            file.write("$_caller_filter = RSpec::CallerFilter.first_non_rspec_line")
          end

          $_caller_filter = nil

          expect {
            require "rspec/support/test_dir/file"
          }.to change { $_caller_filter }.to(include __FILE__)
        end
      end
    end
  end
end
