# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Rails
        # @!parse
        #   # Checks that tests use RSpec `before` hook over Rails `setup`
        #   # method.
        #   #
        #   # @example
        #   #   # bad
        #   #   setup do
        #   #     allow(foo).to receive(:bar)
        #   #   end
        #   #
        #   #   # good
        #   #   before do
        #   #     allow(foo).to receive(:bar)
        #   #   end
        #   #
        #   class AvoidSetupHook < RuboCop::Cop::RSpec::Base; end
        AvoidSetupHook = ::RuboCop::Cop::RSpecRails::AvoidSetupHook
      end
    end
  end
end
