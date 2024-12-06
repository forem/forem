module Fog
  module Parsers
    module AWS
      module DNS
        class HealthCheck < Fog::Parsers::Base
          def reset
            @health_check = {}
            @health_check_config = {}
            @response = {}
          end

          def end_element(name)
            case name
            when 'HealthCheck'
              @response[name] = @health_check
            when 'HealthCheckConfig'
              @health_check[name] = @health_check_config
              @health_check_config = {}
            when 'Id', 'CallerReference'
              @health_check[name] = value
            when 'HealthCheckVersion'
              @health_check[name] = value.to_i
            when 'IPAddress', 'Port', 'Type', 'ResourcePath', 'FullyQualifiedDomainName', 'SearchString', 'FailureThreshold'
              @health_check_config[name] = value
            when 'RequestInterval'
              @health_check_config[name] = value.to_i
            end
          end
        end
      end
    end
  end
end
