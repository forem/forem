module Fog
  module Parsers
    module AWS
      module Storage
        class ListMultipartUploads < Fog::Parsers::Base
          def reset
            @upload = { 'Initiator' => {}, 'Owner' => {} }
            @response = { 'Upload' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Initiator'
              @in_initiator = true
            when 'Owner'
              @in_owner = true
            end
          end

          def end_element(name)
            case name
            when 'Bucket', 'KeyMarker', 'NextKeyMarker', 'NextUploadIdMarker', 'UploadIdMarker'
              @response[name] = value
            when 'DisplayName', 'ID'
              if @in_initiator
                @upload['Initiator'][name] = value
              elsif @in_owner
                @upload['Owner'][name] = value
              end
            when 'Initiated'
              @upload[name] = Time.parse(value)
            when 'Initiator'
              @in_initiator = false
            when 'IsTruncated'
              @response[name] = value == 'true'
            when 'Key', 'StorageClass', 'UploadId'
              @upload[name] = value
            when 'MaxUploads'
              @response[name] = value.to_i
            when 'Owner'
              @in_owner = false
            when 'Upload'
              @response['Upload'] << @upload
              @upload = { 'Initiator' => {}, 'Owner' => {} }
            end
          end
        end
      end
    end
  end
end
