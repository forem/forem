module Fog
  module Parsers
    module AWS
      module Storage
        class GetService < Fog::Parsers::Base
          def reset
            @bucket = {}
            @response = { 'Owner' => {}, 'Buckets' => [] }
          end

          def end_element(name)
            case name
            when 'Bucket'
              @response['Buckets'] << @bucket
              @bucket = {}
            when 'CreationDate'
              @bucket['CreationDate'] = Time.parse(value)
            when 'DisplayName', 'ID'
              @response['Owner'][name] = value
            when 'Name'
              @bucket[name] = value
            end
          end
        end
      end
    end
  end
end
