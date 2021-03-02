require 'rspec/core/bisect/utilities'

module RSpec::Core
  RSpec.describe Bisect::Notifier do
    class ExampleFormatterClass
      def foo(notification); end
    end

    let(:formatter) { instance_spy(ExampleFormatterClass) }
    let(:notifier) { Bisect::Notifier.new(formatter) }

    it 'publishes events to the wrapped formatter' do
      notifier.publish :foo, :length => 15, :width => 12

      expect(formatter).to have_received(:foo).with(an_object_having_attributes(
        :length => 15, :width => 12
      ))
    end

    it 'does not publish events the formatter does not recognize' do
      expect {
        notifier.publish :unrecognized_event, :length => 15, :width => 12
      }.not_to raise_error
    end
  end

  RSpec.describe Bisect::Channel do
    include RSpec::Support::InSubProcess

    it "supports sending objects from a child process back to the parent" do
      channel = Bisect::Channel.new

      in_sub_process do
        channel.send(:value_from_child)
      end

      expect(channel.receive).to eq :value_from_child
    end

    describe "in a UTF-8 encoding context (where possible)" do
      if defined?(Encoding)
        around(:each) do |example|
          old_external = old_internal = nil

          ignoring_warnings do
            old_external, Encoding.default_external = Encoding.default_external, Encoding::UTF_8
            old_internal, Encoding.default_internal = Encoding.default_internal, Encoding::UTF_8
          end

          example.run

          ignoring_warnings do
            Encoding.default_external = old_external
            Encoding.default_internal = old_internal
          end
        end
      end

      it "successfully sends binary data within a process" do
        channel = Bisect::Channel.new
        expect { channel.send("\xF8") }.not_to raise_error
      end

      it "successfully sends binary data from a child process to its parent process" do
        channel = Bisect::Channel.new

        in_sub_process do
          channel.send("\xF8")
        end

        expect(channel.receive).to eq("\xF8")
      end
    end

  end
end
