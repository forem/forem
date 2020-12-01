require 'rspec/core/reporter'
require 'rspec/core/formatters/fallback_message_formatter'

module RSpec::Core::Formatters
  RSpec.describe FallbackMessageFormatter do
    include FormatterSupport

    describe "#message" do
      it 'writes the message to the output' do
        expect {
          send_notification :message, message_notification('Custom Message')
        }.to change { formatter_output.string }.
          from(excluding 'Custom Message').
          to(including 'Custom Message')
      end
    end
  end
end
