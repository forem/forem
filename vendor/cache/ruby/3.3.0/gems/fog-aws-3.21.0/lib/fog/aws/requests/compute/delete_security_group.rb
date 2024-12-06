module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Delete a security group that you own
        #
        # ==== Parameters
        # * group_name<~String> - Name of the security group, must be nil if id is specified
        # * group_id<~String> - Id of the security group, must be nil if name is specified
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteSecurityGroup.html]
        def delete_security_group(name, id = nil)
          if name && id
            raise Fog::AWS::Compute::Error.new("May not specify both group_name and group_id")
          end
          if name
            type_id    = 'GroupName'
            identifier = name
          else
            type_id    = 'GroupId'
            identifier = id
          end
          request(
            'Action'    => 'DeleteSecurityGroup',
            type_id     => identifier,
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_security_group(name, id = nil)
          if name == 'default'
            raise Fog::AWS::Compute::Error.new("InvalidGroup.Reserved => The security group 'default' is reserved")
          end

          if name && id
            raise Fog::AWS::Compute::Error.new("May not specify both group_name and group_id")
          end

          if name
            id, _ = self.data[:security_groups].find { |_,v| v['groupName'] == name }
          end

          unless self.data[:security_groups][id]
            raise Fog::AWS::Compute::NotFound.new("The security group '#{id}' does not exist")
          end

          response = Excon::Response.new

          used_by_groups = []

          # ec2 authorizations
          self.region_data.each do |_, key_data|
            key_data[:security_groups].each do |group_id, group|
              next if group == self.data[:security_groups][group_id]

              group['ipPermissions'].each do |group_ip_permission|
                group_ip_permission['groups'].each do |group_group_permission|
                  if group_group_permission['groupId'] == group_id &&
                      group_group_permission['userId'] == self.data[:owner_id]
                    used_by_groups << "#{key_data[:owner_id]}:#{group['groupName']}"
                  end
                end
              end
            end
          end

          # rds authorizations
          Fog::AWS::RDS::Mock.data[self.region].each do |_, data|
            (data[:security_groups] || []).each do |group_name, group|
              (group["EC2SecurityGroups"] || []).each do |ec2_group|
                if ec2_group["EC2SecurityGroupName"] == name
                  used_by_groups << "#{group["OwnerId"]}:#{group_name}"
                end
              end
            end
          end

          active_instances = self.data[:instances].values.select do |instance|
            if instance['groupSet'].include?(name) && instance['instanceState'] != "terminated"
              instance
            end
          end

          unless used_by_groups.empty?
            raise Fog::AWS::Compute::Error.new("InvalidGroup.InUse => Group #{self.data[:owner_id]}:#{name} is used by groups: #{used_by_groups.uniq.join(" ")}")
          end

          if active_instances.any?
            raise Fog::AWS::Compute::Error.new("InUse => There are active instances using security group '#{name}'")
          end

          self.data[:security_groups].delete(id)
          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'return'    => true
          }
          response
        end
      end
    end
  end
end
