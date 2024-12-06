# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Base < Solargraph::LanguageServer::Message::Base
          include Solargraph::LanguageServer::UriHelpers

          attr_reader :filename

          def post_initialize
            @filename = uri_to_file(params['textDocument']['uri'])
          end
        end
      end
    end
  end
end
