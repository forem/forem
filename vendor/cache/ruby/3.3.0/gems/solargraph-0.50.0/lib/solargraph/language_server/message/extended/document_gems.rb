# frozen_string_literal: true

require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Update YARD documentation for installed gems. If the `rebuild`
        # parameter is true, rebuild existing yardocs.
        #
        class DocumentGems < Base
          def process
            cmd = "yard gems"
            cmd += " --rebuild" if params['rebuild']
            o, s = Open3.capture2(cmd)
            if s != 0
              host.show_message "An error occurred while building gem documentation.", LanguageServer::MessageTypes::ERROR
              set_result({
                status: 'err'
              })
            else
              set_result({
                status: 'ok'
              })
            end
          end
        end
      end
    end
  end
end
