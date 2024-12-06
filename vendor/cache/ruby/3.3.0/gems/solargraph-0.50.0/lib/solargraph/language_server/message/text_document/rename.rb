# frozen_string_literal: true

module Solargraph::LanguageServer::Message::TextDocument
  class Rename < Base
    def process
      locs = host.references_from(params['textDocument']['uri'], params['position']['line'], params['position']['character'], strip: true)
      changes = {}
      locs.each do |loc|
        uri = file_to_uri(loc.filename)
        changes[uri] ||= []
        changes[uri].push({
          range: loc.range.to_hash,
          newText: params['newName']
        })
      end
      set_result changes: changes
    end
  end
end
