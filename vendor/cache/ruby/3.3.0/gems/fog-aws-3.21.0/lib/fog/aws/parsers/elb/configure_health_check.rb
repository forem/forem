module Fog
  module Parsers
    module AWS
      module ELB
        class ConfigureHealthCheck < Fog::Parsers::Base
          def reset
            @health_check = {}
            @response = { 'ConfigureHealthCheckResult' => {}, 'ResponseMetadata' => {} }
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'Target'
              @health_check[name] = value
            when 'Interval', 'Timeout', 'UnhealthyThreshold', 'HealthyThreshold'
              @health_check[name] = value.to_i

            when 'HealthCheck'
              @response['ConfigureHealthCheckResult'][name] = @health_check

            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
