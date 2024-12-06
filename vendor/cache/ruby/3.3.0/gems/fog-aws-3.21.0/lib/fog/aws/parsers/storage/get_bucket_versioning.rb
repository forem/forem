module Fog
  module Parsers
    module AWS
      module Storage
        class GetBucketVersioning < Fog::Parsers::Base
          def reset
            @response = { 'VersioningConfiguration' => {} }
          end

          def end_element(name)
            case name
            when 'Status', 'MfaDelete'
              @response['VersioningConfiguration'][name] = value
            end
          end
        end
      end
    end
  end
end
