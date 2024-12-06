module Fog
  module Parsers
    module AWS
      module Storage
        class ListParts < Fog::Parsers::Base
          def reset
            @part = {}
            @response = { 'Initiator' => {}, 'Part' => [] }
          end

          def end_element(name)
            case name
            when 'Bucket', 'Key', 'NextPartNumberMarker', 'PartNumberMarker', 'StorageClass', 'UploadId'
              @response[name] = value
            when 'DisplayName', 'ID'
              @response['Initiator'][name] = value
            when 'ETag'
              @part[name] = value
            when 'IsTruncated'
              @response[name] = value == 'true'
            when 'LastModified'
              @part[name] = Time.parse(value)
            when 'MaxParts'
              @response[name] = value.to_i
            when 'Part'
              @response['Part'] << @part
              @part = {}
            when 'PartNumber', 'Size'
              @part[name] = value.to_i
            end
          end
        end
      end
    end
  end
end
