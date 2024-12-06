module Fog
  module Parsers
    module AWS
      module Storage
        class CopyObject < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'ETag'
              @response[name] = value.gsub('"', '')
            when 'LastModified'
              @response[name] = Time.parse(value)
            end
          end
        end
      end
    end
  end
end
