# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      # Messages in the Extended module are custom to the Solargraph
      # implementation of the language server. In the protocol, the method
      # names should start with "$/" so clients that don't recognize them can
      # ignore them, as per the LSP specification.
      #
      module Extended
        autoload :Document,        'solargraph/language_server/message/extended/document'
        autoload :Search,          'solargraph/language_server/message/extended/search'
        autoload :CheckGemVersion, 'solargraph/language_server/message/extended/check_gem_version'
        autoload :DocumentGems,    'solargraph/language_server/message/extended/document_gems'
        autoload :DownloadCore,    'solargraph/language_server/message/extended/download_core'
        autoload :Environment,     'solargraph/language_server/message/extended/environment'
      end
    end
  end
end
