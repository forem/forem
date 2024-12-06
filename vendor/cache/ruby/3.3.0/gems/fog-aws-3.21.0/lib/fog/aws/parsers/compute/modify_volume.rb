module Fog
  module Parsers
    module AWS
      module Compute
        class ModifyVolume < Fog::Parsers::Base
          def reset
            @response = {'volumeModification' => {}}
          end

          def end_element(name)
            case name
            when 'modificationState', 'originalVolumeType', 'statusMessage', 'targetVolumeType', 'volumeId'
              @response['volumeModification'][name] = value
            when 'startTime', 'endTime'
              @response['volumeModification'][name] = Time.parse(value)
            when 'originalIops', 'originalSize', 'progress', 'targetIops', 'targetSize'
              @response['volumeModification'][name] = value.to_i
            when 'requestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
