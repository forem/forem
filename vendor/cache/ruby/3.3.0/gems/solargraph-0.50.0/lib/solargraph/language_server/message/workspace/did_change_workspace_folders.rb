# frozen_string_literal: true

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWorkspaceFolders < Solargraph::LanguageServer::Message::Base
    def process
      add_folders
      remove_folders
    end

    private

    def add_folders
      return unless params['event'] && params['event']['added']
      host.prepare_folders params['event']['added']
    end

    def remove_folders
      return unless params['event'] && params['event']['removed']
      params['event']['removed'].each do |folder|
        host.remove_folders params['event']['removed']
      end
    end
  end
end
