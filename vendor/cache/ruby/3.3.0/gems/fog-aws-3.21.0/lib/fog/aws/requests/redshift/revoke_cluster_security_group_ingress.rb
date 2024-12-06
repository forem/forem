module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/revoke_cluster_security_group_ingress'

        # ==== Parameters
        #
        # @param [Hash] options
		# * :cluster_security_group_name - required - (String)
		#    The name of the security Group from which to revoke the ingress rule.
		# * :cidrip - (String)
		#    The IP range for which to revoke access. This range must be a valid Classless
		#    Inter-Domain Routing (CIDR) block of IP addresses. If CIDRIP is specified,
		#    EC2SecurityGroupName and EC2SecurityGroupOwnerId cannot be provided.
		# * :ec2_security_group_name - (String)
		#    The name of the EC2 Security Group whose access is to be revoked. If
		#    EC2SecurityGroupName is specified, EC2SecurityGroupOwnerId must also be
		#    provided and CIDRIP cannot be provided.
		# * :ec2_security_group_owner_id - (String)
		#    The AWS account number of the owner of the security group specified in the
		#    EC2SecurityGroupName parameter. The AWS access key ID is not an acceptable
		#    value. If EC2SecurityGroupOwnerId is specified, EC2SecurityGroupName must
		#    also be provided. and CIDRIP cannot be provided. Example: 111122223333
	    #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_RevokeClusterSecurityGroupIngress.html
        def revoke_cluster_security_group_ingress(options = {})
          cluster_security_group_name = options[:cluster_security_group_name]
          cidrip                      = options[:cidrip]
          ec2_security_group_name     = options[:ec2_security_group_name]
          ec2_security_group_owner_id = options[:ec2_security_group_owner_id]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
			:parser     => Fog::Parsers::Redshift::AWS::RevokeClusterSecurityGroupIngress.new
          }

          params[:query]['Action']                     = 'RevokeClusterSecurityGroupIngress'
          params[:query]['ClusterSecurityGroupName']   = cluster_security_group_name if cluster_security_group_name
          params[:query]['CIDRIP']					   = cidrip if cidrip
          params[:query]['EC2SecurityGroupName']       = ec2_security_group_name if ec2_security_group_name
          params[:query]['EC2SecurityGroupOwnerId']    = ec2_security_group_owner_id if ec2_security_group_owner_id

          request(params)
        end
      end
    end
  end
end
