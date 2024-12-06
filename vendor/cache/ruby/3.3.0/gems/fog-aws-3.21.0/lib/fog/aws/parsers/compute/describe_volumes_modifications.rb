module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVolumesModifications < Fog::Parsers::Base
          def reset
            @response     = { 'volumeModificationSet' => [] }
            @modification = {}
          end

          def end_element(name)
            case name
            when 'modificationState', 'originalVolumeType', 'statusMessage', 'targetVolumeType', 'volumeId'
              @modification[name] = value
            when 'startTime', 'endTime'
              @modification[name] = Time.parse(value)
            when 'originalIops', 'originalSize', 'progress', 'targetIops', 'targetSize'
              @modification[name] = value.to_i
            when 'requestId'
              @response[name] = value
            when 'item'
              @response['volumeModificationSet'] << @modification.dup
              @modification = {}
            end
          end
        end
      end
    end
  end
end
