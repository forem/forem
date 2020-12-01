RSpec.describe "Aggregating failures" do
  shared_examples_for "failure aggregation" do |exception_attribute, example_meta|
    context "via the `aggregate_failures` method" do
      context 'when the example has an expectation failure, plus an `after` hook and an `around` hook failure' do
        it 'presents a flat list of three failures' do
          ex = nil

          RSpec.describe do
            ex = example "ex", example_meta do
              aggregate_failures { expect(1).to be_even }
            end
            after { raise "after" }
            around { |example| example.run; raise "around" }
          end.run

          expect(ex.execution_result.__send__(exception_attribute)).to have_attributes(
            :all_exceptions => [
              an_object_having_attributes(:message => /expected.*even\?/),
              an_object_having_attributes(:message => 'after'),
              an_object_having_attributes(:message => 'around')
            ]
          )
        end
      end

      context 'when the example has multiple expectation failures, plus an `after` hook and an `around` hook failure' do
        it 'nests the expectation failures so that they can be labeled with the aggregation block label' do
          ex = nil

          RSpec.describe do
            ex = example "ex", example_meta do
              aggregate_failures do
                expect(1).to be_even
                expect(2).to be_odd
              end
            end
            after { raise "after" }
            around { |example| example.run; raise "around" }
          end.run

          exception = ex.execution_result.__send__(exception_attribute)

          expect(exception).to have_attributes(
            :all_exceptions => [
              an_object_having_attributes(:class   => RSpec::Expectations::MultipleExpectationsNotMetError),
              an_object_having_attributes(:message => 'after'),
              an_object_having_attributes(:message => 'around')
            ]
          )

          expect(exception.all_exceptions.first.all_exceptions).to match [
            an_object_having_attributes(:message => /expected.*even\?/),
            an_object_having_attributes(:message => /expected.*odd\?/)
          ]
        end
      end
    end

    context "via `:aggregate_failures` metadata" do
      it 'applies `aggregate_failures` to examples or groups tagged with `:aggregate_failures`' do
        ex = nil

        RSpec.describe "Aggregate failures", :aggregate_failures do
          ex = it "has multiple failures", example_meta do
            expect(1).to be_even
            expect(2).to be_odd
          end
        end.run

        expect(ex.execution_result).not_to be_pending_fixed
        expect(ex.execution_result.status).to eq(:pending) if example_meta.key?(:pending)
        expect(ex.execution_result.__send__(exception_attribute)).to have_attributes(
          :all_exceptions => [
            an_object_having_attributes(:message => /expected.*even\?/),
            an_object_having_attributes(:message => /expected.*odd\?/)
          ]
        )
      end

      context 'when the example has an exception, plus another error' do
        it 'reports it as a multiple exception error' do
          ex = nil

          RSpec.describe "Aggregate failures", :aggregate_failures do
            ex = example "fail and raise", example_meta do
              expect(1).to be_even
              boom
            end
          end.run

          expect(ex.execution_result.__send__(exception_attribute)).to have_attributes(
            :all_exceptions => [
              an_object_having_attributes(:message => /expected.*even\?/),
              an_object_having_attributes(:class => NameError, :message => /boom/)
            ]
          )
        end
      end

      context 'when the example has multiple exceptions, plus another error' do
        it 'reports it as a flat multiple exception error' do
          ex = nil

          RSpec.describe "Aggregate failures", :aggregate_failures do
            ex = example "fail and raise", example_meta do
              expect(1).to be_even
              expect(2).to be_odd
              boom
            end
          end.run

          expect(ex.execution_result.__send__(exception_attribute)).to have_attributes(
            :all_exceptions => [
              an_object_having_attributes(:message => /expected.*even\?/),
              an_object_having_attributes(:message => /expected.*odd\?/),
              an_object_having_attributes(:class => NameError, :message => /boom/)
            ]
          )
        end
      end
    end
  end

  context "for a non-pending example" do
    include_examples "failure aggregation", :exception, {}

    it 'does not interfere with other `around` hooks' do
      events = []

      RSpec.describe "Outer" do
        around do |ex|
          events << :outer_before
          ex.run
          events << :outer_after
        end

        context "aggregating failures", :aggregate_failures do
          context "inner" do
            around do |ex|
              events << :inner_before
              ex.run
              events << :inner_after
            end

            it "has multiple failures" do
              events << :example_before
              expect(1).to be_even
              expect(2).to be_odd
              events << :example_after
            end
          end
        end
      end.run

      expect(events).to eq([:outer_before, :inner_before, :example_before,
                            :example_after, :inner_after, :outer_after])
    end
  end

  context "for a pending example" do
    include_examples "failure aggregation", :pending_exception, :pending => true
  end
end
