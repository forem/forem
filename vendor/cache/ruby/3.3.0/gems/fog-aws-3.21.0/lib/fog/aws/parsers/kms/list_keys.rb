module Fog
  module Parsers
    module AWS
      module KMS
        class ListKeys < Fog::Parsers::Base
          def reset
            @response = { 'Keys' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Keys'
              @keys = []
            when 'member'
              @key = {}
            end
          end

          def end_element(name)
            case name
            when 'KeyId', 'KeyArn'
              @key[name] = value
            when 'member'
              @keys << @key
            when 'Keys'
              @response['Keys'] = @keys
            when 'Truncated'
              @response['Truncated'] = (value == 'true')
            when 'NextMarker'
              @response['Marker'] = value
            end
          end
        end
      end
    end
  end
end
