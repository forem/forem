module Fog
  module Parsers
    module AWS
      module Compute
        class CreateSnapshot < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'description', 'ownerId', 'progress', 'snapshotId', 'status', 'volumeId', 'statusMessage'
              @response[name] = value
            when 'requestId'
              @response[name] = value
            when 'startTime'
              @response[name] = Time.parse(value)
            when 'volumeSize'
              @response[name] = value.to_i
            end
          end
        end
      end
    end
  end
end
