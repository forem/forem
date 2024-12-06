# frozen_string_literal: true

module Octokit
  # Allows warnings to be suppressed via environment variable.
  module Warnable
    module_function

    # Wrapper around Kernel#warn to print warnings unless
    # OCTOKIT_SILENT is set to true.
    #
    # @return [nil]
    def octokit_warn(*message)
      warn message unless ENV['OCTOKIT_SILENT']
    end
  end
end
