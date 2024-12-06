module Fog
  module Parsers
    module AWS
      module CDN
        class GetInvalidation < Fog::Parsers::Base
          def reset
            @response = { 'InvalidationBatch' => { 'Path' => [] } }
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'Path'
              @response['InvalidationBatch'][name] << value
            when 'Id', 'Status', 'CreateTime'
              @response[name] = value
            when 'CallerReference'
              @response['InvalidationBatch'][name] = value
            end
          end
        end
      end
    end
  end
end
