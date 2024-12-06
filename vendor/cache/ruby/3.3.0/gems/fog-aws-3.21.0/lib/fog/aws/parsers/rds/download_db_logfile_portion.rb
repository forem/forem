module Fog
  module Parsers
    module AWS
      module RDS
        class DownloadDBLogFilePortion < Fog::Parsers::Base
          def reset
            @response = { 'DownloadDBLogFilePortionResult' => {}, 'ResponseMetadata' => {} }
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            key = (name == 'RequestId') ? 'ResponseMetadata' : 'DownloadDBLogFilePortionResult'
            @response[key][name] = value
          end
        end
      end
    end
  end
end
