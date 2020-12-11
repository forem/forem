# encoding: utf-8
require 'rspec/core/formatters/html_formatter'

module RSpec
  module Core
    module Formatters
      RSpec.describe HtmlFormatter do
        include FormatterSupport

        let(:root) { File.expand_path("#{File.dirname(__FILE__)}/../../../..") }

        let(:expected_file) do
          "#{File.dirname(__FILE__)}/html_formatted.html"
        end

        let(:actual_html) do
          run_example_specs_with_formatter('html') do |runner|
            allow(runner.configuration).to receive(:load_spec_files) do
              runner.configuration.files_to_run.map { |f| load File.expand_path(f) }
            end

            # This is to minimize churn on backtrace lines
            runner.configuration.backtrace_exclusion_patterns << /.*/
            runner.configuration.backtrace_inclusion_patterns << /formatter_specs\.rb/
          end
        end

        let(:expected_html) do
          File.read(expected_file)
        end

        # Uncomment this group temporarily in order to overwrite the expected
        # with actual.  Use with care!!!
        describe "file generator", :if => ENV['GENERATE'] do
          it "generates a new comparison file" do
            Dir.chdir(root) do
              File.open(expected_file, 'w') {|io| io.write(actual_html)}
            end
          end
        end

        def extract_backtrace_from(doc)
          doc.search("div.backtrace").
            collect {|e| e.at("pre").inner_html}.
            collect {|e| e.split("\n")}.flatten.
            select  {|e| e =~ /formatter_specs\.rb/}
        end

        describe 'produced HTML', :if => RUBY_VERSION <= '2.0.0' do
          # Rubies before 2 are a wild west of different outputs, and it's not
          # worth the effort to maintain accurate fixtures for all of them.
          # Since we are verifying fixtures on other rubies, if this code at
          # least runs we can be reasonably confident the output is right since
          # behaviour variances that we care about across versions is neglible.
          it 'is present' do
            expect(actual_html).to be
          end
        end

        describe 'produced HTML', :slow, :if => RUBY_VERSION >= '2.0.0' do
          it "is identical to the one we designed manually", :pending => (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby') do
            expect(actual_html).to eq(expected_html)
          end

          context 'with mathn loaded' do
            include MathnIntegrationSupport

            it "is identical to the one we designed manually", :slow, :pending => (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby') do
              with_mathn_loaded do
                expect(actual_html).to eq(expected_html)
              end
            end
          end
        end
      end
    end
  end
end
