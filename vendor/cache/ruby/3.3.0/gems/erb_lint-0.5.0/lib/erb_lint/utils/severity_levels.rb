# frozen_string_literal: true

module ERBLint
  module Utils
    module SeverityLevels
      SEVERITY_NAMES = [:info, :refactor, :convention, :warning, :error, :fatal].freeze

      SEVERITY_CODE_TABLE = { I: :info, R: :refactor, C: :convention,
                              W: :warning, E: :error, F: :fatal, }.freeze

      def severity_level_for_name(name)
        SEVERITY_NAMES.index(name || :error) + 1
      end
    end
  end
end
