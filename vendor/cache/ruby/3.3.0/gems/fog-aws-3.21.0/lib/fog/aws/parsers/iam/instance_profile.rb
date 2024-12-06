module Fog
  module Parsers
    module AWS
      module IAM
        require 'fog/aws/parsers/iam/base_instance_profile'

        class InstanceProfile < Fog::Parsers::AWS::IAM::BaseInstanceProfile
          def reset
            super
            @response = {}
          end

          def finished_instance_profile(profile)
            @response['InstanceProfile'] = profile
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response[name] = value
            end
            super
          end
        end
      end
    end
  end
end
