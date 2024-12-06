# frozen_string_literal: true

require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class FoldingRange < Base
          def process
            result = host.folding_ranges(params['textDocument']['uri']).map do |range|
              {
                startLine: range.start.line,
                startCharacter: 0,
                endLine: range.ending.line - 1,
                endCharacter: 0,
                kind: 'region'
              }
            end
            set_result result
          end
        end
      end
    end
  end
end
