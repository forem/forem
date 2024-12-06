module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Deletes a network ACL entry
        #
        # ==== Parameters
        # * network_acl_id<~String> - The ID of the network ACL
        # * rule_number<~Integer>   - The rule number of the entry to delete.
        # * egress<~Boolean>        - Indicates whether the rule is an egress rule (true) or ingress rule (false)
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteNetworkAclEntry.html]
        def delete_network_acl_entry(network_acl_id, rule_number, egress)
          request(
            'Action'       => 'DeleteNetworkAclEntry',
            'NetworkAclId' => network_acl_id,
            'RuleNumber'   => rule_number,
            'Egress'       => egress,
            :parser        => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_network_acl_entry(network_acl_id, rule_number, egress)
          response = Excon::Response.new
          if self.data[:network_acls][network_acl_id]
            if self.data[:network_acls][network_acl_id]['entrySet'].find { |r| r['ruleNumber'] == rule_number && r['egress'] == egress }
              self.data[:network_acls][network_acl_id]['entrySet'].delete_if { |r| r['ruleNumber'] == rule_number && r['egress'] == egress }
            else
              raise Fog::AWS::Compute::Error.new("No rule with that number and egress value")
            end

            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The network ACL '#{network_acl_id}' does not exist")
          end
        end
      end
    end
  end
end
