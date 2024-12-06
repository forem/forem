# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      module Rails
        # @!parse
        #   # Identifies redundant spec type.
        #   #
        #   # After setting up rspec-rails, you will have enabled
        #   # `config.infer_spec_type_from_file_location!` by default in
        #   # spec/rails_helper.rb. This cop works in conjunction with
        #   # this config.
        #   # If you disable this config, disable this cop as well.
        #   #
        #   # @safety
        #   #   This cop is marked as unsafe because
        #   #   `config.infer_spec_type_from_file_location!` may not be enabled.
        #   #
        #   # @example
        #   #   # bad
        #   #   # spec/models/user_spec.rb
        #   #   RSpec.describe User, type: :model do
        #   #   end
        #   #
        #   #   # good
        #   #   # spec/models/user_spec.rb
        #   #   RSpec.describe User do
        #   #   end
        #   #
        #   #   # good
        #   #   # spec/models/user_spec.rb
        #   #   RSpec.describe User, type: :common do
        #   #   end
        #   #
        #   # @example `Inferences` configuration
        #   #   # .rubocop.yml
        #   #   # RSpec/Rails/InferredSpecType:
        #   #   #   Inferences:
        #   #   #     services: service
        #   #
        #   #   # bad
        #   #   # spec/services/user_spec.rb
        #   #   RSpec.describe User, type: :service do
        #   #   end
        #   #
        #   #   # good
        #   #   # spec/services/user_spec.rb
        #   #   RSpec.describe User do
        #   #   end
        #   #
        #   #   # good
        #   #   # spec/services/user_spec.rb
        #   #   RSpec.describe User, type: :common do
        #   #   end
        #   #
        #   class InferredSpecType < RuboCop::Cop::RSpec::Base; end
        InferredSpecType = ::RuboCop::Cop::RSpecRails::InferredSpecType
      end
    end
  end
end
