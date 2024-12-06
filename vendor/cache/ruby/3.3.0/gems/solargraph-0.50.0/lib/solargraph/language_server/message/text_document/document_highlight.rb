# frozen_string_literal: true

module Solargraph::LanguageServer::Message::TextDocument
  class DocumentHighlight < Base
    def process
      locs = host.references_from(params['textDocument']['uri'], params['position']['line'], params['position']['character'], strip: true, only: true)
      result = locs.map do |loc|
        {
          range: loc.range.to_hash,
          kind: 1
        }
      end
      set_result result
    end
  end
end
