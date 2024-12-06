module Fog
  module AWS
    class RDS
      class SecurityGroup < Fog::Model
        identity   :id, :aliases => ['DBSecurityGroupName']
        attribute  :description, :aliases => 'DBSecurityGroupDescription'
        attribute  :ec2_security_groups, :aliases => 'EC2SecurityGroups', :type => :array
        attribute  :ip_ranges, :aliases => 'IPRanges', :type => :array
        attribute  :owner_id, :aliases => 'OwnerId'

        def ready?
          (ec2_security_groups + ip_ranges).all?{|ingress| ingress['Status'] == 'authorized'}
        end

        def destroy
          requires :id
          service.delete_db_security_group(id)
          true
        end

        def save
          requires :id
          requires :description

          data = service.create_db_security_group(id, description).body['CreateDBSecurityGroupResult']['DBSecurityGroup']
          merge_attributes(data)
          true
        end

        # group_owner_id defaults to the current owner_id
        def authorize_ec2_security_group(group_name, group_owner_id=owner_id)
          key = group_name.match(/^sg-/) ? 'EC2SecurityGroupId' : 'EC2SecurityGroupName'
          authorize_ingress({
            key                       => group_name,
            'EC2SecurityGroupOwnerId' => group_owner_id
          })
        end

        def authorize_cidrip(cidrip)
          authorize_ingress({'CIDRIP' => cidrip})
        end

        # Add the current machine to the RDS security group.
        def authorize_me
          authorize_ip_address(Fog::CurrentMachine.ip_address)
        end

        # Add the ip address to the RDS security group.
        def authorize_ip_address(ip)
          authorize_cidrip("#{ip}/32")
        end

        def authorize_ingress(opts)
          data = service.authorize_db_security_group_ingress(id, opts).body['AuthorizeDBSecurityGroupIngressResult']['DBSecurityGroup']
          merge_attributes(data)
        end

        # group_owner_id defaults to the current owner_id
        def revoke_ec2_security_group(group_name, group_owner_id=owner_id)
          key = group_name.match(/^sg-/) ? 'EC2SecurityGroupId' : 'EC2SecurityGroupName'
          revoke_ingress({
            key                       => group_name,
            'EC2SecurityGroupOwnerId' => group_owner_id
          })
        end

        def revoke_cidrip(cidrip)
          revoke_ingress({'CIDRIP' => cidrip})
        end

        def revoke_ingress(opts)
          data = service.revoke_db_security_group_ingress(id, opts).body['RevokeDBSecurityGroupIngressResult']['DBSecurityGroup']
          merge_attributes(data)
        end
      end
    end
  end
end
