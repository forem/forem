require 'fog/aws/models/compute/security_group'

module Fog
  module AWS
    class Compute
      class SecurityGroups < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::SecurityGroup

        # Creates a new security group
        #
        # AWS.security_groups.new
        #
        # ==== Returns
        #
        # Returns the details of the new image
        #
        #>> AWS.security_groups.new
        #  <Fog::AWS::Compute::SecurityGroup
        #    name=nil,
        #    description=nil,
        #    ip_permissions=nil,
        #    owner_id=nil
        #    vpc_id=nil
        #  >
        #

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # Returns an array of all security groups that have been created
        #
        # AWS.security_groups.all
        #
        # ==== Returns
        #
        # Returns an array of all security groups
        #
        #>> AWS.security_groups.all
        #  <Fog::AWS::Compute::SecurityGroups
        #    filters={}
        #    [
        #      <Fog::AWS::Compute::SecurityGroup
        #        name="default",
        #        description="default group",
        #        ip_permissions=[{"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>-1, "toPort"=>-1, "ipRanges"=>[], "ipProtocol"=>"icmp"}, {"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>0, "toPort"=>65535, "ipRanges"=>[], "ipProtocol"=>"tcp"}, {"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>0, "toPort"=>65535, "ipRanges"=>[], "ipProtocol"=>"udp"}],
        #        owner_id="312571045469"
        #        vpc_id=nill
        #      >
        #    ]
        #  >
        #

        def all(filters_arg = filters)
          unless filters_arg.is_a?(Hash)
            Fog::Logger.deprecation("all with #{filters_arg.class} param is deprecated, use all('group-name' => []) instead [light_black](#{caller.first})[/]")
            filters_arg = {'group-name' => [*filters_arg]}
          end
          self.filters = filters_arg
          data = service.describe_security_groups(filters).body
          load(data['securityGroupInfo'])
        end

        # Used to retrieve a security group
        # group name is required to get the associated flavor information.
        #
        # You can run the following command to get the details:
        # AWS.security_groups.get("default")
        #
        # ==== Returns
        #
        #>> AWS.security_groups.get("default")
        #  <Fog::AWS::Compute::SecurityGroup
        #    name="default",
        #    description="default group",
        #    ip_permissions=[{"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>-1, "toPort"=>-1, "ipRanges"=>[], "ipProtocol"=>"icmp"}, {"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>0, "toPort"=>65535, "ipRanges"=>[], "ipProtocol"=>"tcp"}, {"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>0, "toPort"=>65535, "ipRanges"=>[], "ipProtocol"=>"udp"}],
        #    owner_id="312571045469"
        #    vpc_id=nil
        #  >
        #

        def get(group_name)
          if group_name
            self.class.new(:service => service).all('group-name' => group_name).first
          end
        end

        # Used to retrieve a security group
        # group id is required to get the associated flavor information.
        #
        # You can run the following command to get the details:
        # AWS.security_groups.get_by_id("default")
        #
        # ==== Returns
        #
        #>> AWS.security_groups.get_by_id("sg-123456")
        #  <Fog::AWS::Compute::SecurityGroup
        #    name="default",
        #    description="default group",
        #    ip_permissions=[{"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>-1, "toPort"=>-1, "ipRanges"=>[], "ipProtocol"=>"icmp"}, {"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>0, "toPort"=>65535, "ipRanges"=>[], "ipProtocol"=>"tcp"}, {"groups"=>[{"groupName"=>"default", "userId"=>"312571045469"}], "fromPort"=>0, "toPort"=>65535, "ipRanges"=>[], "ipProtocol"=>"udp"}],
        #    owner_id="312571045469"
        #  >
        #

        def get_by_id(group_id)
          if group_id
            self.class.new(:service => service).all('group-id' => group_id).first
          end
        end
      end
    end
  end
end
