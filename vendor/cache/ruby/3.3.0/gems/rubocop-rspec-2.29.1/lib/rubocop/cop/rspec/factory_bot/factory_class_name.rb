# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module FactoryBot
        # @!parse
        #   # Use string value when setting the class attribute explicitly.
        #   #
        #   # This cop would promote faster tests by lazy-loading of
        #   # application files. Also, this could help you suppress potential
        #   # bugs in combination with external libraries by avoiding a preload
        #   # of application files from the factory files.
        #   #
        #   # @example
        #   #   # bad
        #   #   factory :foo, class: Foo do
        #   #   end
        #   #
        #   #   # good
        #   #   factory :foo, class: 'Foo' do
        #   #   end
        #   #
        #   class FactoryClassName < ::RuboCop::Cop::Base; end
        FactoryClassName = ::RuboCop::Cop::FactoryBot::FactoryClassName
      end
    end
  end
end
