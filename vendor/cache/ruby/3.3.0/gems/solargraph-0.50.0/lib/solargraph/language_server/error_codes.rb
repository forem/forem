# frozen_string_literal: true

module Solargraph
  module LanguageServer
    # The ErrorCode constants for the language server protocol.
    #
    module ErrorCodes
      PARSE_ERROR =            -32700
      INVALID_REQUEST =        -32600
      METHOD_NOT_FOUND =       -32601
      INVALID_PARAMS =         -32602
      INTERNAL_ERROR =         -32603
      SERVER_ERROR_START =     -32099
      SERVER_ERROR_END =       -32000
      SERVER_NOT_INITIALIZED = -32002
      UNKNOWN_ERROR_CODE =     -32001
      REQUEST_CANCELLED =      -32800
    end
  end
end
