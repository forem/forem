# frozen_string_literal: true

module KnapsackPro
  module Client
    module API
      module V1
        class Base
          private

          def self.action_class
            KnapsackPro::Client::API::Action
          end
        end
      end
    end
  end
end
