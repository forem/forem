# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class OnTypeFormatting < Base
          def process
            # @todo Temporarily disabled due to conflicts with VSCode formatting on type
            # src = host.send(:library).checkout(uri_to_file(params['textDocument']['uri']))
            # fragment = src.fragment_at(params['position']['line'], params['position']['character'] - 1)
            # offset = fragment.send(:offset)
            # if fragment.string? and params['ch'] == '{' and src.code[offset - 1, 2] == '#{'
            #   set_result(
            #     [
            #       {
            #         range: {
            #           start: params['position'],
            #           end: params['position']
            #         },
            #         newText: '}'
            #       }
            #     ]
            #   )
            # else
            #   # @todo Is `nil` or `[]` more appropriate here?
            #   set_result nil
            # end
          end
        end
      end
    end
  end
end
