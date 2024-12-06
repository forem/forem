module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVpcClassicLinkDnsSupport < Fog::Parsers::Base
          def reset
            @vpc      = {}
            @response = { 'vpcs' => [] }
          end

          def end_element(name)
            case name
            when 'vpcId'
              @vpc[name] = value
            when 'classicLinkDnsSupported'
              @vpc[name] = value == 'true'
            when 'item'
              @response['vpcs'] << @vpc
              @vpc = {}
            end
          end
        end
      end
    end
  end
end
