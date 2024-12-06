module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVpcAttribute < Fog::Parsers::Base
          def reset
            @response                = { }
            @in_enable_dns_support   = false
            @in_enable_dns_hostnames = false
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'enableDnsSupport'
              @in_enable_dns_support   = true
            when 'enableDnsHostnames'
              @in_enable_dns_hostnames = true
            end
          end

          def end_element(name)
            if @in_enable_dns_support
              case name
              when 'value'
                @response['enableDnsSupport'] = (value == 'true')
              when 'enableDnsSupport'
                @in_enable_dns_support = false
              end
            elsif @in_enable_dns_hostnames
              case name
              when 'value'
                @response['enableDnsHostnames'] = (value == 'true')
              when 'enableDnsHostnames'
                @in_enable_dns_hostnames = false
              end
            else
              case name
              when 'requestId', 'vpcId'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
