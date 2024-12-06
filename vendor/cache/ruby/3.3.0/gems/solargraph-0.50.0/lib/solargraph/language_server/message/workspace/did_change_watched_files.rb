# frozen_string_literal: true

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Solargraph::LanguageServer::Message::Base
    CREATED = 1
    CHANGED = 2
    DELETED = 3

    include Solargraph::LanguageServer::UriHelpers

    def process
      need_catalog = false
      to_create = []
      to_delete = []

      # @param change [Hash]
      params['changes'].each do |change|
        if change['type'] == CREATED
          to_create << change['uri']
          need_catalog = true
        elsif change['type'] == CHANGED
          next if host.open?(change['uri'])
          to_create << change['uri']
          need_catalog = true
        elsif change['type'] == DELETED
          to_delete << change['uri']
          need_catalog = true
        else
          set_error Solargraph::LanguageServer::ErrorCodes::INVALID_PARAMS, "Unknown change type ##{change['type']} for #{uri_to_file(change['uri'])}"
        end
      end

      host.create *to_create
      host.delete *to_delete

      # Force host to catalog libraries after file changes (see castwide/solargraph#139)
      host.catalog if need_catalog
    end
  end
end
