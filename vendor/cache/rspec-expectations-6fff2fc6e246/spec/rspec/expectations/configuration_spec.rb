module RSpec
  module Expectations
    RSpec.describe Configuration do
      let(:config) { Configuration.new }

      describe "#backtrace_formatter" do
        let(:original_backtrace) { %w[ clean-me/a.rb other/file.rb clean-me/b.rb ] }
        let(:cleaned_backtrace)  { %w[ other/file.rb ] }

        let(:formatted_backtrace) do
          config.backtrace_formatter.format_backtrace(original_backtrace)
        end

        before do
          @old_patterns = RSpec.configuration.backtrace_exclusion_patterns
          @orig_full_backtrace = RSpec.configuration.full_backtrace?
          RSpec.configuration.full_backtrace = false
          RSpec.configuration.backtrace_exclusion_patterns = [/clean-me/]
        end

        after do
          RSpec.configuration.backtrace_exclusion_patterns = @old_patterns
          RSpec.configuration.full_backtrace = @orig_full_backtrace
        end

        it "defaults to rspec-core's backtrace formatter when rspec-core is loaded" do
          expect(config.backtrace_formatter).to be(RSpec.configuration.backtrace_formatter)
          expect(formatted_backtrace).to eq(cleaned_backtrace)
        end

        it "defaults to a null formatter when rspec-core is not loaded" do
          RSpec::Mocks.with_temporary_scope do
            rspec_dup = ::RSpec.dup
            class << rspec_dup; undef configuration; end
            stub_const("RSpec", rspec_dup)

            expect(formatted_backtrace).to eq(original_backtrace)
          end
        end

        it "can be set to another backtrace formatter" do
          config.backtrace_formatter = double(:format_backtrace => ['a'])
          expect(formatted_backtrace).to eq(['a'])
        end
      end

      context 'on an interpreter that does not provide BasicObject', :uses_should, :unless => defined?(::BasicObject) do
        def with_delegate
          in_sub_process_if_possible do
            require 'delegate'
            RSpec::Expectations::Syntax.disable_should(Delegator)
            yield
          end
        end

        let(:klass) do
          Class.new(SimpleDelegator) do
            def delegated?; true; end
          end
        end

        let(:instance) { klass.new(Object.new) }

        it 'provides a means to manually add it Delegator' do
          with_delegate do
            instance.should_not respond_to(:delegated?) # because #should is being delegated...
            config.add_should_and_should_not_to Delegator
            instance.should respond_to(:delegated?) # now it should work!
          end
        end
      end

      describe "#include_chain_clauses_in_custom_matcher_descriptions?" do
        it "is false by default" do
          expect(config.include_chain_clauses_in_custom_matcher_descriptions?).to be false
        end

        it "can be set to true" do
          config.include_chain_clauses_in_custom_matcher_descriptions = true
          expect(config.include_chain_clauses_in_custom_matcher_descriptions?).to be true
        end

        it "can be set back to false" do
          config.include_chain_clauses_in_custom_matcher_descriptions = true
          config.include_chain_clauses_in_custom_matcher_descriptions = false
          expect(config.include_chain_clauses_in_custom_matcher_descriptions?).to be false
        end
      end

      describe "#max_formatted_output_length=" do
        before do
          @orig_max_formatted_output_length = RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length
        end

        after do
          config.max_formatted_output_length = @orig_max_formatted_output_length
        end

        let(:object_with_large_inspect_string) { Struct.new(:value).new("a"*300) }

        it "sets the maximum object formatter length" do
          config.max_formatted_output_length = 10
          expect(RSpec::Support::ObjectFormatter.format(object_with_large_inspect_string)).to eq("#<stru...aaa\">")
        end

        it "formats the entire object when set to nil" do
          config.max_formatted_output_length = nil
          expect(RSpec::Support::ObjectFormatter.format(object_with_large_inspect_string)).to eq(object_with_large_inspect_string.inspect)
        end
      end

      describe "#warn_about_potential_false_positives?" do
        it "is true by default" do
          expect(config.warn_about_potential_false_positives?).to be true
        end

        it "can be set to false" do
          config.warn_about_potential_false_positives = false
          expect(config.warn_about_potential_false_positives?).to be false
        end

        it "can be set back to true" do
          config.warn_about_potential_false_positives = false
          config.warn_about_potential_false_positives = true
          expect(config.warn_about_potential_false_positives?).to be true
        end
      end

      describe '#on_potential_false_positives' do
        it 'is set to :warn by default' do
          expect(config.on_potential_false_positives).to eq :warn
        end

        it 'can be set to :nothing' do
          config.on_potential_false_positives = :nothing
          expect(config.on_potential_false_positives).to eq :nothing
        end

        it 'can be set back to :warn' do
          config.on_potential_false_positives = :nothing
          config.on_potential_false_positives = :warn
          expect(config.on_potential_false_positives).to eq :warn
        end

        it 'can be set to :raise' do
          config.on_potential_false_positives = :raise
          expect(config.on_potential_false_positives).to eq :raise
        end
      end

      shared_examples "configuring the expectation syntax" do
        before do
          @orig_syntax = RSpec::Matchers.configuration.syntax
        end

        after do
          configure_syntax(@orig_syntax)
        end

        it 'can limit the syntax to :should' do
          configure_syntax :should
          configured_syntax.should eq([:should])

          3.should eq(3)
          3.should_not eq(4)
          lambda { expect(6).to eq(6) }.should raise_error(NameError)
        end

        it 'is a no-op when configured to :should twice' do
          configure_syntax :should
          method_added_count = 0
          allow(Expectations::Syntax.default_should_host).to receive(:method_added) { method_added_count += 1 }
          configure_syntax :should

          method_added_count.should eq(0)
        end

        it 'can limit the syntax to :expect' do
          configure_syntax :expect
          expect(configured_syntax).to eq([:expect])

          expect(3).to eq(3)
          expect { 3.should eq(3) }.to raise_error(NameError)
          expect { 3.should_not eq(3) }.to raise_error(NameError)
        end

        it 'is a no-op when configured to :expect twice' do
          allow(RSpec::Matchers).to receive(:method_added).and_raise("no methods should be added here")

          configure_syntax :expect
          configure_syntax :expect
        end

        describe "`:should` being enabled by default deprecation" do
          before { configure_default_syntax }

          it "warns when the should syntax is called by default" do
            expected_arguments = [
              /Using.*without explicitly enabling/,
              { :replacement => "the new `:expect` syntax or explicitly enable `:should` with `config.expect_with(:rspec) { |c| c.syntax = :should }`" }
            ]

            expect(RSpec).to receive(:deprecate).with(*expected_arguments)
            3.should eq(3)
          end

          it "includes the call site in the deprecation warning by default" do
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1)
            3.should eq(3)
          end

          it "does not warn when only the should syntax is explicitly configured" do
            configure_syntax(:should)
            RSpec.should_not receive(:deprecate)
            3.should eq(3)
          end

          it "does not warn when both the should and expect syntaxes are explicitly configured" do
            configure_syntax([:should, :expect])
            expect(RSpec).not_to receive(:deprecate)
            3.should eq(3)
          end
        end

        it 'can re-enable the :should syntax' do
          configure_syntax :expect
          configure_syntax [:should, :expect]
          configured_syntax.should eq([:should, :expect])

          3.should eq(3)
          3.should_not eq(4)
          expect(3).to eq(3)
        end

        it 'can re-enable the :expect syntax' do
          configure_syntax :should
          configure_syntax [:should, :expect]
          configured_syntax.should eq([:should, :expect])

          3.should eq(3)
          3.should_not eq(4)
          expect(3).to eq(3)
        end
      end

      def configure_default_syntax
        RSpec::Matchers.configuration.reset_syntaxes_to_default
      end

      describe "configuring rspec-expectations directly" do
        it_behaves_like "configuring the expectation syntax" do
          def configure_syntax(syntax)
            RSpec::Matchers.configuration.syntax = syntax
          end

          def configured_syntax
            RSpec::Matchers.configuration.syntax
          end
        end
      end

      describe "configuring using the rspec-core config API" do
        it_behaves_like "configuring the expectation syntax" do
          def configure_syntax(syntax)
            RSpec.configure do |rspec|
              rspec.expect_with :rspec do |c|
                c.syntax = syntax
              end
            end
          end

          def configured_syntax
            RSpec.configure do |rspec|
              rspec.expect_with :rspec do |c|
                return c.syntax
              end
            end
          end
        end
      end

      it 'enables both syntaxes by default' do
        # This is kinda a hack, but since we want to enforce use of
        # the expect syntax within our specs here, we have modified the
        # config setting, which makes it hard to get at the original
        # default value. in spec_helper.rb we store the default value
        # in $default_expectation_syntax so we can use it here.
        expect($default_expectation_syntax).to contain_exactly(:expect, :should) # rubocop:disable Style/GlobalVars
      end
    end
  end
end
