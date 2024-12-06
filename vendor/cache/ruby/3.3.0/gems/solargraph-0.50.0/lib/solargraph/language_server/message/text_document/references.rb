# frozen_string_literal: true

module Solargraph::LanguageServer::Message::TextDocument
  class References < Base
    def process
      locs = host.references_from(params['textDocument']['uri'], params['position']['line'], params['position']['character'])
      result = locs.map do |loc|
        {
          uri: file_to_uri(loc.filename),
          range: loc.range.to_hash
        }
      end
      set_result result
    end
  end
end
