module Fog
  module Parsers
    module AWS
      module Storage
        class DeleteMultipleObjects < Fog::Parsers::Base
          def reset
            @deleted = { 'Deleted' => {} }
            @error = { 'Error' => {} }
            @response = { 'DeleteResult' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Deleted'
              @in_deleted = true
            end
          end

          def end_element(name)
            case name
            when 'Deleted'
              @response['DeleteResult'] << @deleted
              @deleted = { 'Deleted' => {} }
              @in_deleted = false
            when 'Error'
              @response['DeleteResult'] << @error
              @error = { 'Error' => {} }
            when 'Key', 'VersionId'
              if @in_deleted
                @deleted['Deleted'][name] = value
              else
                @error['Error'][name] = value
              end
            when 'DeleteMarker', 'DeletemarkerVersionId'
              @deleted['Deleted'][name] = value
            when 'Code', 'Message'
              @error['Error'][name] = value
            end
          end
        end
      end
    end
  end
end
