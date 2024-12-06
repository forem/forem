# frozen_string_literal: true

module Solargraph
  module LanguageServer
    # The Transport namespace contains concrete implementations of
    # communication protocols for language servers.
    #
    module Transport
      autoload :Adapter,    'solargraph/language_server/transport/adapter'
      autoload :DataReader, 'solargraph/language_server/transport/data_reader'
    end
  end
end
