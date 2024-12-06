# frozen_string_literal: true

module Solargraph::LanguageServer::Message::TextDocument
  class PrepareRename < Base
    def process
      line = params['position']['line']
      col = params['position']['character']
      set_result host.sources.find(params['textDocument']['uri']).cursor_at(Solargraph::Position.new(line, col)).range.to_hash
    end
  end
end
