module Fog
  module AWS
    class Compute
      class SecurityGroup < Fog::Model
        identity  :name,            :aliases => 'groupName'
        attribute :description,     :aliases => 'groupDescription'
        attribute :group_id,        :aliases => 'groupId'
        attribute :ip_permissions,  :aliases => 'ipPermissions'
        attribute :ip_permissions_egress,  :aliases => 'ipPermissionsEgress'
        attribute :owner_id,        :aliases => 'ownerId'
        attribute :vpc_id,          :aliases => 'vpcId'
        attribute :tags,            :aliases => 'tagSet'

        # Authorize access by another security group
        #
        #  >> g = AWS.security_groups.all(:description => "something").first
        #  >> g.authorize_group_and_owner("some_group_name", "1234567890")
        #
        # == Parameters:
        # group::
        #   The name of the security group you're granting access to.
        #
        # owner::
        #   The owner id for security group you're granting access to.
        #
        # == Returns:
        #
        # An excon response object representing the result
        #
        #  <Excon::Response:0x101fc2ae0
        #    @status=200,
        #    @body={"requestId"=>"some-id-string",
        #           "return"=>true},
        #    headers{"Transfer-Encoding"=>"chunked",
        #            "Date"=>"Mon, 27 Dec 2010 22:12:57 GMT",
        #            "Content-Type"=>"text/xml;charset=UTF-8",
        #            "Server"=>"AmazonEC2"}
        #

        def authorize_group_and_owner(group, owner = nil)
          Fog::Logger.deprecation("authorize_group_and_owner is deprecated, use authorize_port_range with :group option instead")

          requires_one :name, :group_id

          service.authorize_security_group_ingress(
            name,
            'GroupId'                    => group_id,
            'SourceSecurityGroupName'    => group,
            'SourceSecurityGroupOwnerId' => owner
          )
        end

        # Authorize a new port range for a security group
        #
        #  >> g = AWS.security_groups.all(:description => "something").first
        #  >> g.authorize_port_range(20..21)
        #
        # == Parameters:
        # range::
        #   A Range object representing the port range you want to open up. E.g., 20..21
        #
        # options::
        #   A hash that can contain any of the following keys:
        #    :cidr_ip (defaults to "0.0.0.0/0")
        #    :cidr_ipv6 cannot be used with :cidr_ip
        #    :group - ("account:group_name" or "account:group_id"), cannot be used with :cidr_ip or :cidr_ipv6
        #    :ip_protocol (defaults to "tcp")
        #
        # == Returns:
        #
        # An excon response object representing the result
        #
        #  <Excon::Response:0x101fc2ae0
        #    @status=200,
        #    @body={"requestId"=>"some-id-string",
        #           "return"=>true},
        #    headers{"Transfer-Encoding"=>"chunked",
        #            "Date"=>"Mon, 27 Dec 2010 22:12:57 GMT",
        #            "Content-Type"=>"text/xml;charset=UTF-8",
        #            "Server"=>"AmazonEC2"}
        #

        def authorize_port_range(range, options = {})
          requires_one :name, :group_id

          ip_permission = fetch_ip_permission(range, options)

          if options[:direction].nil? || options[:direction] == 'ingress'
            authorize_port_range_ingress group_id, ip_permission
          elsif options[:direction] == 'egress'
            authorize_port_range_egress group_id, ip_permission
          end
        end

        def authorize_port_range_ingress(group_id, ip_permission)
          service.authorize_security_group_ingress(
            name,
            'GroupId'       => group_id,
            'IpPermissions' => [ ip_permission ]
          )
        end

        def authorize_port_range_egress(group_id, ip_permission)
          service.authorize_security_group_egress(
            name,
            'GroupId'       => group_id,
            'IpPermissions' => [ ip_permission ]
          )
        end

        # Removes an existing security group
        #
        # security_group.destroy
        #
        # ==== Returns
        #
        # True or false depending on the result
        #

        def destroy
          requires_one :name, :group_id

          if group_id.nil?
            service.delete_security_group(name)
          else
            service.delete_security_group(nil, group_id)
          end
          true
        end

        # Revoke access by another security group
        #
        #  >> g = AWS.security_groups.all(:description => "something").first
        #  >> g.revoke_group_and_owner("some_group_name", "1234567890")
        #
        # == Parameters:
        # group::
        #   The name of the security group you're revoking access to.
        #
        # owner::
        #   The owner id for security group you're revoking access access to.
        #
        # == Returns:
        #
        # An excon response object representing the result
        #
        #  <Excon::Response:0x101fc2ae0
        #    @status=200,
        #    @body={"requestId"=>"some-id-string",
        #           "return"=>true},
        #    headers{"Transfer-Encoding"=>"chunked",
        #            "Date"=>"Mon, 27 Dec 2010 22:12:57 GMT",
        #            "Content-Type"=>"text/xml;charset=UTF-8",
        #            "Server"=>"AmazonEC2"}
        #

        def revoke_group_and_owner(group, owner = nil)
          Fog::Logger.deprecation("revoke_group_and_owner is deprecated, use revoke_port_range with :group option instead")

          requires_one :name, :group_id

          service.revoke_security_group_ingress(
            name,
            'GroupId'                    => group_id,
            'SourceSecurityGroupName'    => group,
            'SourceSecurityGroupOwnerId' => owner
          )
        end

        # Revoke an existing port range for a security group
        #
        #  >> g = AWS.security_groups.all(:description => "something").first
        #  >> g.revoke_port_range(20..21)
        #
        # == Parameters:
        # range::
        #   A Range object representing the port range you want to open up. E.g., 20..21
        #
        # options::
        #   A hash that can contain any of the following keys:
        #    :cidr_ip (defaults to "0.0.0.0/0")
        #    :cidr_ipv6 cannot be used with :cidr_ip
        #    :group - ("account:group_name" or "account:group_id"), cannot be used with :cidr_ip or :cidr_ipv6
        #    :ip_protocol (defaults to "tcp")
        #
        # == Returns:
        #
        # An excon response object representing the result
        #
        #  <Excon::Response:0x101fc2ae0
        #    @status=200,
        #    @body={"requestId"=>"some-id-string",
        #           "return"=>true},
        #    headers{"Transfer-Encoding"=>"chunked",
        #            "Date"=>"Mon, 27 Dec 2010 22:12:57 GMT",
        #            "Content-Type"=>"text/xml;charset=UTF-8",
        #            "Server"=>"AmazonEC2"}
        #

        def revoke_port_range(range, options = {})
          requires_one :name, :group_id

          ip_permission = fetch_ip_permission(range, options)

          if options[:direction].nil? || options[:direction] == 'ingress'
            revoke_port_range_ingress group_id, ip_permission
          elsif options[:direction] == 'egress'
            revoke_port_range_egress group_id, ip_permission
          end
        end

        def revoke_port_range_ingress(group_id, ip_permission)
          service.revoke_security_group_ingress(
            name,
            'GroupId'       => group_id,
            'IpPermissions' => [ ip_permission ]
          )
        end

        def revoke_port_range_egress(group_id, ip_permission)
          service.revoke_security_group_egress(
            name,
            'GroupId'       => group_id,
            'IpPermissions' => [ ip_permission ]
          )
        end

        # Reload a security group
        #
        #  >> g = AWS.security_groups.get(:name => "some_name")
        #  >> g.reload
        #
        #  == Returns:
        #
        #  Up to date model or an exception

        def reload
          if group_id.nil?
            super
            service.delete_security_group(name)
          else
            requires :group_id

            data = begin
              collection.get_by_id(group_id)
            rescue Excon::Errors::SocketError
              nil
            end

            return unless data

            merge_attributes(data.attributes)
            self
          end
        end


        # Create a security group
        #
        #  >> g = AWS.security_groups.new(:name => "some_name", :description => "something")
        #  >> g.save
        #
        # == Returns:
        #
        # True or an exception depending on the result. Keep in mind that this *creates* a new security group.
        # As such, it yields an InvalidGroup.Duplicate exception if you attempt to save an existing group.
        #

        def save
          requires :description, :name
          data = service.create_security_group(name, description, vpc_id).body
          new_attributes = data.reject {|key,value| key == 'requestId'}
          merge_attributes(new_attributes)

          if tags = self.tags
            # expect eventual consistency
            Fog.wait_for { self.reload rescue nil }
            service.create_tags(
              self.group_id,
              tags
            )
          end

          true
        end

        private

        #
        # +group_arg+ may be a string or a hash with one key & value.
        #
        # If group_arg is a string, it is assumed to be the group name,
        # and the UserId is assumed to be self.owner_id.
        #
        # The "account:group" form is deprecated.
        #
        # If group_arg is a hash, the key is the UserId and value is the group.
        def group_info(group_arg)
          if Hash === group_arg
            account = group_arg.keys.first
            group   = group_arg.values.first
          elsif group_arg.match(/:/)
            account, group = group_arg.split(':')
            Fog::Logger.deprecation("'account:group' argument is deprecated. Use {account => group} or just group instead")
          else
            requires :owner_id
            account = owner_id
            group = group_arg
          end

          info = { 'UserId' => account }

          if group.start_with?("sg-")
            # we're dealing with a security group id
            info['GroupId'] = group
          else
            # this has to be a security group name
            info['GroupName'] = group
          end

          info
        end

        def fetch_ip_permission(range, options)
          ip_permission = {
            'FromPort'   => range.begin,
            'ToPort'     => range.end,
            'IpProtocol' => options[:ip_protocol] || 'tcp'
          }

          if options[:group].nil?
            if options[:cidr_ipv6].nil?
              ip_permission['IpRanges'] = [
                { 'CidrIp' => options[:cidr_ip] || '0.0.0.0/0' }
              ]
            else
              ip_permission['Ipv6Ranges'] = [
                { 'CidrIpv6' => options[:cidr_ipv6] }
              ]
            end
          else
            ip_permission['Groups'] = [
              group_info(options[:group])
            ]
          end
          ip_permission
        end
      end
    end
  end
end
