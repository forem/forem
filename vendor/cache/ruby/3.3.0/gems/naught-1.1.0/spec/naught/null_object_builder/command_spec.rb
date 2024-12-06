require 'spec_helper'

module Naught
  describe NullClassBuilder::Command do
    it 'is abstract' do
      command = NullClassBuilder::Command.new(nil)
      expect { command.call }.to raise_error(NotImplementedError)
    end
  end
end
