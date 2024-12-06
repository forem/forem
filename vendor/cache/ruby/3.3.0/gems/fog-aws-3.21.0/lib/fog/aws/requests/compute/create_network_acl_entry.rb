module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Creates a Network ACL entry
        #
        # ==== Parameters
        # * network_acl_id<~String> - The ID of the ACL to add this entry to
        # * rule_number<~Integer>   - The rule number for the entry, between 100 and 32766
        # * protocol<~Integer>      - The IP protocol to which the rule applies. You can use -1 to mean all protocols.
        # * rule_action<~String>    - Allows or denies traffic that matches the rule. (either allow or deny)
        # * cidr_block<~String>     - The CIDR range to allow or deny
        # * egress<~Boolean>        - Indicates whether this rule applies to egress traffic from the subnet (true) or ingress traffic to the subnet (false).
        # * options<~Hash>:
        # *   'Icmp.Code'           - ICMP code, required if protocol is 1
        # *   'Icmp.Type'           - ICMP type, required if protocol is 1
        # *   'PortRange.From'      - The first port in the range, required if protocol is 6 (TCP) or 17 (UDP)
        # *   'PortRange.To'        - The last port in the range, required if protocol is 6 (TCP) or 17 (UDP)
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-CreateNetworkAclEntry.html]
        def create_network_acl_entry(network_acl_id, rule_number, protocol, rule_action, cidr_block, egress, options = {})
          request({
            'Action'       => 'CreateNetworkAclEntry',
            'NetworkAclId' => network_acl_id,
            'RuleNumber'   => rule_number,
            'Protocol'     => protocol,
            'RuleAction'   => rule_action,
            'Egress'       => egress,
            'CidrBlock'    => cidr_block,
            :parser        => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def create_network_acl_entry(network_acl_id, rule_number, protocol, rule_action, cidr_block, egress, options = {})
          response = Excon::Response.new
          if self.data[:network_acls][network_acl_id]

            if self.data[:network_acls][network_acl_id]['entrySet'].find { |r| r['ruleNumber'] == rule_number && r['egress'] == egress }
              raise Fog::AWS::Compute::Error.new("Already a rule with that number")
            end

            data = {
              'ruleNumber'   => rule_number,
              'protocol'     => protocol,
              'ruleAction'   => rule_action,
              'egress'       => egress,
              'cidrBlock'    => cidr_block,
              'icmpTypeCode' => {},
              'portRange'    => {}
            }
            data['icmpTypeCode']['code'] = options['Icmp.Code']      if options['Icmp.Code']
            data['icmpTypeCode']['type'] = options['Icmp.Type']      if options['Icmp.Type']
            data['portRange']['from']    = options['PortRange.From'] if options['PortRange.From']
            data['portRange']['to']      = options['PortRange.To']   if options['PortRange.To']
            self.data[:network_acls][network_acl_id]['entrySet'] << data

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
