# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        autoload :Base,              'solargraph/language_server/message/text_document/base'
        autoload :Completion,        'solargraph/language_server/message/text_document/completion'
        autoload :DidOpen,           'solargraph/language_server/message/text_document/did_open'
        autoload :DidChange,         'solargraph/language_server/message/text_document/did_change'
        autoload :DidClose,          'solargraph/language_server/message/text_document/did_close'
        autoload :DidSave,           'solargraph/language_server/message/text_document/did_save'
        autoload :Hover,             'solargraph/language_server/message/text_document/hover'
        autoload :SignatureHelp,     'solargraph/language_server/message/text_document/signature_help'
        autoload :DiagnosticsQueue,  'solargraph/language_server/message/text_document/diagnostics_queue'
        autoload :OnTypeFormatting,  'solargraph/language_server/message/text_document/on_type_formatting'
        autoload :Definition,        'solargraph/language_server/message/text_document/definition'
        autoload :DocumentSymbol,    'solargraph/language_server/message/text_document/document_symbol'
        autoload :Formatting,        'solargraph/language_server/message/text_document/formatting'
        autoload :References,        'solargraph/language_server/message/text_document/references'
        autoload :Rename,            'solargraph/language_server/message/text_document/rename'
        autoload :PrepareRename,     'solargraph/language_server/message/text_document/prepare_rename'
        autoload :FoldingRange,      'solargraph/language_server/message/text_document/folding_range'
        autoload :DocumentHighlight, 'solargraph/language_server/message/text_document/document_highlight'
      end
    end
  end
end
