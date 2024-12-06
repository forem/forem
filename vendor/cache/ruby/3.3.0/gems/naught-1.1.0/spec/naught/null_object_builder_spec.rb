require 'spec_helper'

module Naught
  class NullClassBuilder
    module Commands
      class TestCommand
      end
    end
  end

  describe NullClassBuilder do
    subject(:builder) { NullClassBuilder.new }
    it 'responds to commands defined in NullObjectBuilder::Commands' do
      expect(builder).to respond_to(:test_command)
    end

    it 'translates method calls into command invocations including arguments' do
      test_command = double
      expect(NullClassBuilder::Commands::TestCommand).to receive(:new).
        with(builder, 'foo', 42).
        and_return(test_command)
      expect(test_command).to receive(:call).and_return('COMMAND RESULT')
      expect(builder.test_command('foo', 42)).to eq('COMMAND RESULT')
    end

    it 'handles missing non-command missing methods normally' do
      expect(builder).not_to respond_to(:nonexistant_method)
      expect { builder.nonexistent_method }.to raise_error(NoMethodError)
    end
  end
end
