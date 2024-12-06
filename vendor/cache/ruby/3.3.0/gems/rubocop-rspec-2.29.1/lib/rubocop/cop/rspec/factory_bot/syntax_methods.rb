# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # @!parse
        #   # Use shorthands from `FactoryBot::Syntax::Methods` in your specs.
        #   #
        #   # @safety
        #   #   The autocorrection is marked as unsafe because the cop
        #   #   cannot verify whether you already include
        #   #   `FactoryBot::Syntax::Methods` in your test suite.
        #   #
        #   #   If you're using Rails, add the following configuration to
        #   #   `spec/support/factory_bot.rb` and be sure to require that file
        #   #   in `rails_helper.rb`:
        #   #
        #   #   [source,ruby]
        #   #   ----
        #   #   RSpec.configure do |config|
        #   #     config.include FactoryBot::Syntax::Methods
        #   #   end
        #   #   ----
        #   #
        #   #   If you're not using Rails:
        #   #
        #   #   [source,ruby]
        #   #   ----
        #   #   RSpec.configure do |config|
        #   #     config.include FactoryBot::Syntax::Methods
        #   #
        #   #     config.before(:suite) do
        #   #       FactoryBot.find_definitions
        #   #     end
        #   #   end
        #   #   ----
        #   #
        #   # @example
        #   #   # bad
        #   #   FactoryBot.create(:bar)
        #   #   FactoryBot.build(:bar)
        #   #   FactoryBot.attributes_for(:bar)
        #   #
        #   #   # good
        #   #   create(:bar)
        #   #   build(:bar)
        #   #   attributes_for(:bar)
        #   #
        #   class SyntaxMethods < ::RuboCop::Cop::Base; end
        SyntaxMethods = ::RuboCop::Cop::FactoryBot::SyntaxMethods
      end
    end
  end
end
