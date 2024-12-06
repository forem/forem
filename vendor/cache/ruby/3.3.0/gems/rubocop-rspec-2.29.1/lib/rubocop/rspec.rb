# frozen_string_literal: true

module RuboCop
  # RuboCop RSpec project namespace
  module RSpec
    PROJECT_ROOT   = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join('config', 'default.yml').freeze

    private_constant(:CONFIG_DEFAULT, :PROJECT_ROOT)

    ::RuboCop::ConfigObsoletion.files << PROJECT_ROOT.join('config',
                                                           'obsoletion.yml')
  end
end
