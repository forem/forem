module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_vpc_attribute'
        # Describes a vpc attribute value
        #
        # ==== Parameters
        # * vpc_id<~String>    - The ID of the VPC you want to describe an attribute of
        # * attribute<~String> - The attribute to describe, must be one of 'enableDnsSupport' or 'enableDnsHostnames'
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String>           - Id of request
        # * 'vpcId'<~String>               - The ID of the VPC
        # * 'enableDnsSupport'<~Boolean>   - Flag indicating whether DNS resolution is enabled for the VPC (if requested)
        # * 'enableDnsHostnames'<~Boolean> - Flag indicating whether the instances launched in the VPC get DNS hostnames (if requested)
        #
        # (Amazon API Reference)[http://docs.amazonwebservices.com/AWSEC2/2014-02-01/APIReference/ApiReference-query-DescribeVpcAttribute.html]
        def describe_vpc_attribute(vpc_id, attribute)
          request(
            'Action'    => 'DescribeVpcAttribute',
            'VpcId'     => vpc_id,
            'Attribute' => attribute,
            :parser     => Fog::Parsers::AWS::Compute::DescribeVpcAttribute.new
          )
        end
      end

      class Mock
        def describe_vpc_attribute(vpc_id, attribute)
          response = Excon::Response.new
          if vpc = self.data[:vpcs].find{ |v| v['vpcId'] == vpc_id }
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'vpcId'     => vpc_id
            }

            case attribute
            when 'enableDnsSupport', 'enableDnsHostnames'
              response.body[attribute] = vpc[attribute]
            else
              raise Fog::AWS::Compute::Error.new("Illegal attribute '#{attribute}' specified")
            end
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The VPC '#{vpc_id}' does not exist")
          end
        end
      end
    end
  end
end
