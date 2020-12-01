module RSpec::Core::Notifications
  RSpec.describe FailedExampleNotification do
    before do
      allow(RSpec.configuration).to receive(:color_enabled?).and_return(true)
    end

    it "uses the default color for the shared example backtrace line" do
      example = nil
      group = RSpec.describe "testing" do
        shared_examples_for "a" do
          example = it "fails" do
            expect(1).to eq(2)
          end
        end
        it_behaves_like "a"
      end
      group.run
      exception_presenter= RSpec::Core::Formatters::ExceptionPresenter.new(example.execution_result.exception, example)
      fne = FailedExampleNotification.new(example, exception_presenter)
      lines = fne.colorized_message_lines
      expect(lines).to include(match("\\e\\[37mShared Example Group:"))
    end
  end
end
