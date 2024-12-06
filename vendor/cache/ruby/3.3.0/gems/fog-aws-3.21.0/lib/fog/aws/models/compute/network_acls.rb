require 'fog/aws/models/compute/network_acl'

module Fog
  module AWS
    class Compute
      class NetworkAcls < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::NetworkAcl

        # Creates a new network ACL
        #
        # AWS.network_acls.new
        #
        # ==== Returns
        #
        # Returns the details of the new network ACL
        #
        #>> <Fog::AWS::Compute::NetworkAcl
        #     network_acl_id=nil,
        #     vpc_id=nil,
        #     default=nil,
        #     entries=nil,
        #     associations=nil,
        #     tags=nil
        # >
        #
        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Returns an array of all network ACLs that have been created
        #
        # AWS.network_acls.all
        #
        # ==== Returns
        #
        # Returns an array of all network ACLs
        #
        #>> AWS.network_acls.all
        #  <Fog::AWS::Compute::NetworkAcls
        #    filters={}
        #    [
        #      <Fog::AWS::Compute::NetworkAcl
        #        network_acl_id="acl-abcdefgh",
        #        vpc_id="vpc-abcdefgh",
        #        default=true,
        #        entries=[
        #          {
        #            "icmpTypeCode" => {},
        #            "portRange"    => {},
        #            "ruleNumber"   => 32767,
        #            "protocol"     => -1,
        #            "ruleAction"   => "deny",
        #            "egress"       => false,
        #            "cidrBlock"    => "0.0.0.0/0"
        #          },
        #          {
        #            "icmpTypeCode" => {},
        #            "portRange"    => {},
        #            "ruleNumber"   => 32767,
        #            "protocol"     => -1,
        #            "ruleAction"   => "deny",
        #            "egress"       => true,
        #            "cidrBlock"    => "0.0.0.0/0"
        #          }
        #        ],
        #        associations=[
        #          {
        #            "networkAclAssociationId" => "aclassoc-abcdefgh",
        #            "networkAclId"            => "acl-abcdefgh",
        #            "subnetId"                => "subnet-abcdefgh"
        #          }
        #        ],
        #        tags={}
        #      >
        #    ]
        #  >
        #
        def all(filters_arg = filters)
          filters = filters_arg
          data = service.describe_network_acls(filters).body
          load(data['networkAclSet'])
        end

        # Used to retrieve a network interface
        # network interface id is required to get any information
        #
        # You can run the following command to get the details:
        # AWS.network_interfaces.get("eni-11223344")
        #
        # ==== Returns
        #
        #>> AWS.network_acls.get("acl-abcdefgh")
        #  <Fog::AWS::Compute::NetworkAcl
        #    network_acl_id="acl-abcdefgh",
        #    vpc_id="vpc-abcdefgh",
        #    default=true,
        #    entries=[
        #      {
        #        "icmpTypeCode" => {},
        #        "portRange"    => {},
        #        "ruleNumber"   => 32767,
        #        "protocol"     => -1,
        #        "ruleAction"   => "deny",
        #        "egress"       => false,
        #        "cidrBlock"    => "0.0.0.0/0"
        #      },
        #      {
        #        "icmpTypeCode" => {},
        #        "portRange"    => {},
        #        "ruleNumber"   => 32767,
        #        "protocol"     => -1,
        #        "ruleAction"   => "deny",
        #        "egress"       => true,
        #        "cidrBlock"    => "0.0.0.0/0"
        #      }
        #    ],
        #    associations=[
        #      {
        #        "networkAclAssociationId" => "aclassoc-abcdefgh",
        #        "networkAclId"            => "acl-abcdefgh",
        #        "subnetId"                => "subnet-abcdefgh"
        #      }
        #    ],
        #    tags={}
        #  >
        def get(nacl_id)
          self.class.new(:service => service).all('network-acl-id' => nacl_id).first if nacl_id
        end
      end
    end
  end
end
