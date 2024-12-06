module Fog
  module Parsers
    module AWS
      module IAM
        require 'fog/aws/parsers/iam/base_instance_profile'
        class ListInstanceProfiles < Fog::Parsers::AWS::IAM::BaseInstanceProfile
          def reset
            super
            @response = {'InstanceProfiles' => []}
          end

          def finished_instance_profile(profile)
            @response['InstanceProfiles'] << profile
          end

          def end_element(name)
            case name
            when 'RequestId', 'Marker'
              @response[name] = value
            when 'IsTruncated'
              @response[name] = (value == 'true')
            end
            super
          end
        end
      end
    end
  end
end
