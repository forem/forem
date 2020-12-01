module RSpec::Expectations
  RSpec.describe FailureAggregator, "when used via `aggregate_failures`" do
    it 'does not raise an error when no expectations fail' do
      expect {
        aggregate_failures do
          expect(1).to be_odd
          expect(2).to be_even
          expect(3).to be_odd
        end
      }.not_to raise_error
    end

    it 'returns true when no expectations fail' do
      expect(
        aggregate_failures do
          expect(1).to be_odd
          expect(2).to be_even
          expect(3).to be_odd
        end
      ).to eq true
    end

    it 'aggregates multiple failures into one exception that exposes all the failures' do
      expect {
        aggregate_failures('block label', :some => :metadata) do
          expect(1).to be_even
          expect(2).to be_odd
          expect(3).to be_even
        end
      }.to raise_error(an_object_having_attributes(
        :class => MultipleExpectationsNotMetError,
        :failures => [
          an_object_having_attributes(:message => "expected `1.even?` to return true, got false"),
          an_object_having_attributes(:message => "expected `2.odd?` to return true, got false"),
          an_object_having_attributes(:message => "expected `3.even?` to return true, got false")
        ],
        :other_errors => [],
        :aggregation_block_label => 'block label',
        :aggregation_metadata => { :some => :metadata }
      ))
    end

    it 'ensures the exposed failures have backtraces' do
      aggregation_line = __LINE__ + 2
      expect {
        aggregate_failures do
          expect(1).to be_even
          expect(2).to be_odd
          expect(3).to be_even
        end
      }.to raise_error do |error|
        expect(error.failures.map(&:backtrace)).to match [
          a_collection_including(a_string_including(__FILE__, (aggregation_line + 1).to_s)),
          a_collection_including(a_string_including(__FILE__, (aggregation_line + 2).to_s)),
          a_collection_including(a_string_including(__FILE__, (aggregation_line + 3).to_s))
        ]
      end
    end

    def common_contiguous_frame_percent(failure, aggregate)
      failure_frames = failure.backtrace.reverse
      aggregate_frames = aggregate.backtrace.reverse

      first_differing_index = failure_frames.zip(aggregate_frames).index { |f, a| f != a }
      100 * (first_differing_index / failure_frames.count.to_f)
    end

    it 'ensures the sub-failure backtraces are in a form that overlaps with the aggregated failure backtrace' do
      if RSpec::Support::Ruby.jruby?
        pending "This is broken on 9.2.x.x" unless RSpec::Support::Ruby.jruby_version < '9.2.0.0'
      end
      # On JRuby, `caller` and `raise` backtraces can differ significantly --
      # I've seen one include java frames but not the other -- and as a result,
      # the backtrace truncation rspec-core does (based on the common part) fails
      # and produces undesirable output. This spec is a guard against that.

      expect {
        aggregate_failures do
          expect(1).to be_even
          expect(2).to be_odd
        end
      }.to raise_error do |error|
        failure_1, failure_2 = error.failures
        expect(common_contiguous_frame_percent(failure_1, error)).to be > 70
        expect(common_contiguous_frame_percent(failure_2, error)).to be > 70
      end
    end

    def notify_error_with(backtrace)
      exception = Exception.new
      exception.set_backtrace backtrace
      RSpec::Support.notify_failure(exception)
    end

    it 'does not stomp the backtrace on failures that have it' do
      backtrace = ["./foo.rb:13"]

      expect {
        aggregate_failures do
          notify_error_with(backtrace)
          notify_error_with(backtrace)
        end
      }.to raise_error do |error|
        expect(error.failures.map(&:backtrace)).to eq([backtrace, backtrace])
      end
    end

    it 'supports nested `aggregate_failures` blocks' do
      expect {
        aggregate_failures("outer") do
          aggregate_failures("inner 2") do
            expect(2).to be_odd
            expect(3).to be_even
          end

          aggregate_failures("inner 1") do
            expect(1).to be_even
          end

          expect(1).to be_even
        end
      }.to raise_error do |error|
        aggregate_failures("failure expectations") do
          expect(error.failures.count).to eq(3)
          expect(error.failures[0]).to be_an_instance_of(RSpec::Expectations::MultipleExpectationsNotMetError)
          expect(error.failures[0].failures.count).to eq(2)
          expect(error.failures[1]).to be_an_instance_of(RSpec::Expectations::ExpectationNotMetError)
          expect(error.failures[2]).to be_an_instance_of(RSpec::Expectations::ExpectationNotMetError)
        end
      end
    end

    it 'raises a normal `ExpectationNotMetError` when only one expectation fails' do
      expect {
        aggregate_failures do
          expect(1).to be_odd
          expect(2).to be_odd
          expect(3).to be_odd
        end
      }.to fail_with("expected `2.odd?` to return true, got false")
    end

    context "when multiple exceptions are notified with the same `:source_id`" do
      it 'keeps only the first' do
        expect {
          aggregate_failures do
            RSpec::Support.notify_failure(StandardError.new("e1"), :source_id => "1")
            RSpec::Support.notify_failure(StandardError.new("e2"), :source_id => "2")
            RSpec::Support.notify_failure(StandardError.new("e3"), :source_id => "1")
            RSpec::Support.notify_failure(StandardError.new("e4"), :source_id => "1")
          end
        }.to raise_error do |e|
          expect(e.failures).to match [
            an_object_having_attributes(:message => "e1"),
            an_object_having_attributes(:message => "e2")
          ]
        end
      end
    end

    context "when an error other than an expectation failure occurs" do
      def expect_error_included_in_aggregated_failure(error)
        expect {
          aggregate_failures do
            expect(2).to be_odd
            raise error
          end
        }.to raise_error(an_object_having_attributes(
          :class => MultipleExpectationsNotMetError,
          :failures => [an_object_having_attributes(
            :message => "expected `2.odd?` to return true, got false"
          )],
          :other_errors => [error]
        ))
      end

      it "includes the error in the raised aggregated failure when an expectation failed as well" do
        expect_error_included_in_aggregated_failure StandardError.new("boom")
      end

      it "handles direct `Exceptions` and not just `StandardError` and descendents" do
        expect_error_included_in_aggregated_failure Exception.new("boom")
      end

      it "allows the error to propagate as-is if there have been no expectation failures so far" do
        error = StandardError.new("boom")

        expect {
          aggregate_failures do
            raise error
          end
        }.to raise_error(error)
      end

      it "prevents later expectations from even running" do
        error = StandardError.new("boom")
        later_expectation_executed = false

        expect {
          aggregate_failures do
            raise error

            later_expectation_executed = true # rubocop:disable Lint/UnreachableCode
            expect(1).to eq(1)
          end
        }.to raise_error(error)

        expect(later_expectation_executed).to be false
      end

      it 'provides an `all_exceptions` array containing failures and other errors' do
        error = StandardError.new("boom")

        expect {
          aggregate_failures do
            expect(2).to be_odd
            raise error
          end
        }.to raise_error do |aggregate_error|
          expect(aggregate_error).to have_attributes(
            :class => MultipleExpectationsNotMetError,
            :all_exceptions => [
              an_object_having_attributes(:message => "expected `2.odd?` to return true, got false"),
              error
            ]
          )
        end
      end
    end

    context "when an expectation failure happens in another thread" do
      # On Ruby 2.5+, the new `report_on_exception` causes the errors in the threads
      # to print warnings, which our rspec-support test harness converts into a test
      # failure since we want to enforce warnings-free code. To prevent the warning,
      # we need to disable the setting here.
      if Thread.respond_to?(:report_on_exception)
        around do |example|
          orig = Thread.report_on_exception
          Thread.report_on_exception = false
          example.run
          Thread.report_on_exception = orig
        end
      end

      it "includes the failure in the failures array if there are other failures" do
        expect {
          aggregate_failures do
            expect(1).to be_even
            Thread.new { expect(2).to be_odd }.join
          end
        }.to raise_error(an_object_having_attributes(
          :class => MultipleExpectationsNotMetError,
          :failures => [
            an_object_having_attributes(:message => "expected `1.even?` to return true, got false"),
            an_object_having_attributes(:message => "expected `2.odd?` to return true, got false")
          ],
          :other_errors => []
        ))
      end

      it "propagates it as-is if there are no other failures or errors" do
        expect {
          aggregate_failures { Thread.new { expect(2).to be_odd }.join }
        }.to fail_with("expected `2.odd?` to return true, got false")
      end
    end

    describe "message formatting" do
      it "enumerates the failures with an index label, the path of each failure and a blank line in between" do
        expect {
          aggregate_failures do
            expect(1).to be_even
            expect(2).to be_odd
            expect(3).to be_even
          end
        }.to fail_including { dedent <<-EOS }
          |  1) expected `1.even?` to return true, got false
          |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 6}#{exception_complement(5)}
          |
          |  2) expected `2.odd?` to return true, got false
          |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 8}#{exception_complement(5)}
          |
          |  3) expected `3.even?` to return true, got false
          |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 10}#{exception_complement(5)}
        EOS
      end

      it 'mentions how many failures there are' do
        expect {
          aggregate_failures do
            expect(1).to be_even
            expect(2).to be_odd
            expect(3).to be_even
          end
        }.to fail_including { dedent <<-EOS }
          |Got 3 failures from failure aggregation block:
          |
          |  1) expected `1.even?` to return true, got false
        EOS
      end

      it 'allows the user to name the `aggregate_failures` block' do
        expect {
          aggregate_failures("testing odd vs even") do
            expect(1).to be_even
            expect(2).to be_odd
            expect(3).to be_even
          end
        }.to fail_including { dedent <<-EOS }
          |Got 3 failures from failure aggregation block "testing odd vs even":
          |
          |  1) expected `1.even?` to return true, got false
        EOS
      end

      context "when another error has occcured" do
        it 'includes it in the failure message' do
          expect {
            aggregate_failures do
              expect(1).to be_even
              raise "boom"
            end
          }.to fail_including { dedent <<-EOS }
            |Got 1 failure and 1 other error from failure aggregation block:
            |
            |  1) expected `1.even?` to return true, got false
            |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 7}#{exception_complement(6)}
            |
            |  2) RuntimeError: boom
            |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 9}#{exception_complement(6)}
          EOS
        end
      end

      context "when the failure messages have multiple lines" do
        RSpec::Matchers.define :fail_with_multiple_lines do
          match { false }
          failure_message do |actual|
            "line 1\n#{actual}\nline 3"
          end
        end

        it "indents them appropriately so that they still line up" do
          expect {
            aggregate_failures do
              expect(:a).to fail_with_multiple_lines
              expect(:b).to fail_with_multiple_lines
            end
          }.to fail_including { dedent <<-EOS }
            |  1) line 1
            |     a
            |     line 3
            |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 7}#{exception_complement(6)}
            |
            |  2) line 1
            |     b
            |     line 3
            |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 11}#{exception_complement(6)}
          EOS
        end

        it 'accounts for the width of the index when indenting' do
          expect {
            aggregate_failures do
              1.upto(10) do |i|
                expect(i).to fail_with_multiple_lines
              end
            end
          }.to fail_including { dedent <<-EOS }
            |  9)  line 1
            |      9
            |      line 3
            |      ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 7}#{exception_complement(7)}
            |
            |  10) line 1
            |      10
            |      line 3
            |      ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 12}#{exception_complement(7)}
          EOS
        end
      end

      context "when the failure messages starts and ends with line breaks (as the `eq` failure message does)" do
        before do
          expect { expect(1).to eq(2) }.to fail_with(
            a_string_starting_with("\n") & ending_with("\n")
          )
        end

        it 'strips the excess line breaks so that it formats well' do
          expect {
            aggregate_failures do
              expect(1).to eq 2
              expect(1).to eq 3
              expect(1).to eq 4
            end
          }.to fail_including { dedent <<-EOS }
            |  1) expected: 2
            |          got: 1
            |
            |     (compared using ==)
            |
            |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 10}#{exception_complement(6)}
            |
            |  2) expected: 3
            |          got: 1
            |
            |     (compared using ==)
            |
            |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 16}#{exception_complement(6)}
            |
            |  3) expected: 4
            |          got: 1
            |
            |     (compared using ==)
            |
            |     ./spec/rspec/expectations/failure_aggregator_spec.rb:#{__LINE__ - 22}#{exception_complement(6)}
          EOS
        end
      end

      # Use a normal `expect(...).to include` expectation rather than
      # a composed matcher here. This provides better failure output
      # because `MultipleExpectationsNotMetError#message` is lazily
      # computed (rather than being computed in `initialize` and passed
      # to `super`), which causes the `inspect` output of the exception
      # to not include the message for some reason.
      def fail_including
        fail { |e| expect(e.message).to include(yield) }
      end

      # Each Ruby version return a different exception complement.
      # This method gets the current version and return the
      # right complement.
      if RSpec::Support::Ruby.mri? && RUBY_VERSION > "1.8.7"
        def exception_complement(block_levels)
          ":in `block (#{block_levels} levels) in <module:Expectations>'"
        end
      elsif RSpec::Support::Ruby.mri?
        def exception_complement(block_levels)
          ""
        end
      elsif RUBY_VERSION > "2.0.0"
        def exception_complement(block_levels)
          ":in `block in Expectations'"
        end
      else
        def exception_complement(block_levels)
          ":in `Expectations'"
        end
      end
    end
  end
end
