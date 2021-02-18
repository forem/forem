RSpec.describe "Failure notification" do
  def capture_errors(&block)
    errors = []
    RSpec::Support.with_failure_notifier(Proc.new { |e, _opts| errors << e }, &block)
    errors
  end

  it "uses the rspec-support notifier to support `aggregate_failures`" do
    dbl = double("Foo")

    expect(capture_errors { dbl.some_unallowed_method }).to match [an_object_having_attributes(
      :message => a_string_including(dbl.inspect, "some_unallowed_method")
    )]
  end

  it "includes the line of future expectation in the notification for an unreceived message" do
    dbl = double("Foo")
    expect(dbl).to receive(:wont_happen); expected_from_line = __LINE__

    error = capture_errors { verify dbl }.first
    expect(error.backtrace.first).to match(/#{File.basename(__FILE__)}:#{expected_from_line}/)
  end

  it "does not allow a double to miscount the number of times a message was recevied when a failure is notified in an alternate way" do
    dbl = double("Foo")
    expect(dbl).not_to receive(:bar)

    capture_errors { dbl.bar }

    expect { verify dbl }.to fail_including("expected: 0 times", "received: 1 time")
  end

  context "when using `aggregate_failures`" do
    specify 'spy failures for unreceived messages are reported correctly' do
      expect {
        aggregate_failures do
          expect(spy).to have_received(:foo)
        end
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
        expect(e).not_to be_a(RSpec::Expectations::MultipleExpectationsNotMetError)
        expect(e.message).to include("expected: 1 time", "received: 0 times")
      end
    end

    specify 'spy failures for messages received with unexpected args are reported correctly' do
      expect {
        aggregate_failures do
          the_spy = spy
          the_spy.foo(1)
          expect(the_spy).to have_received(:foo).with(2)
        end
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
        expect(e).not_to be_a(RSpec::Expectations::MultipleExpectationsNotMetError)
        expect(e.message).to include("expected: (2)", "got: (1)")
      end
    end

    specify "failing negative expectations are only notified once" do
      expect {
        aggregate_failures do
          dbl = double

          expect(dbl).not_to receive(:foo)
          expect(dbl).not_to receive(:bar)

          dbl.foo
          dbl.bar

          verify_all
        end
      }.to raise_error(RSpec::Expectations::MultipleExpectationsNotMetError) do |e|
        expect(e.failures.count).to eq(2)
      end
    end
  end
end
