module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Disassociate an elastic IP address from its instance (if any)
        #
        # ==== Parameters
        # * public_ip<~String> - Public ip to assign to instance
        # * association_id<~String> - Id associating eip to an network interface
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DisassociateAddress.html]
        def disassociate_address(public_ip=nil, association_id=nil)
          request(
            'Action'        => 'DisassociateAddress',
            'PublicIp'      => public_ip,
            'AssociationId' => association_id,
            :idempotent     => true,
            :parser         => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def disassociate_address(public_ip, association_id=nil)
          response = Excon::Response.new
          response.status = 200
          if address = self.data[:addresses][public_ip]
            if address['allocationId'] && association_id.nil?
              raise Fog::AWS::Compute::Error.new("InvalidParameterValue => You must specify an association id when unmapping an address from a VPC instance")
            end
            instance_id = address['instanceId']
            if instance = self.data[:instances][instance_id]
              instance['ipAddress']         = instance['originalIpAddress']
              instance['dnsName']           = Fog::AWS::Mock.dns_name_for(instance['ipAddress'])
            end
            address['instanceId'] = nil
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::AWS::Compute::Error.new("AuthFailure => The address '#{public_ip}' does not belong to you.")
          end
        end
      end
    end
  end
end
