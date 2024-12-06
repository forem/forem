# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module Workspace
        autoload :DidChangeWatchedFiles,     'solargraph/language_server/message/workspace/did_change_watched_files'
        autoload :WorkspaceSymbol,           'solargraph/language_server/message/workspace/workspace_symbol'
        autoload :DidChangeConfiguration,    'solargraph/language_server/message/workspace/did_change_configuration'
        autoload :DidChangeWorkspaceFolders, 'solargraph/language_server/message/workspace/did_change_workspace_folders'
      end
    end
  end
end
