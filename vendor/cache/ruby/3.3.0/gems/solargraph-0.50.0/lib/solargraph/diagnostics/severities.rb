# frozen_string_literal: true

module Solargraph
  module Diagnostics
    # These severity constants match the DiagnosticSeverity constants in the
    # language server protocol.
    #
    module Severities
      ERROR = 1
      WARNING = 2
      INFORMATION = 3
      HINT = 4
    end
  end
end
