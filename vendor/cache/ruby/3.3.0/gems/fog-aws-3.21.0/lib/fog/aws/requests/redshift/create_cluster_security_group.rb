module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/create_cluster_security_group'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_security_group_name - (String)
        #    The name of a cluster security group for which you are requesting details. You
        #    can specify either the Marker parameter or a ClusterSecurityGroupName parameter,
        #    but not both. Example: securitygroup1
        # * :description - required - (String)
        #    A description for the security group.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_CreateClusterSecurityGroup.html
        def create_cluster_security_group(options = {})
          cluster_security_group_name  = options[:cluster_security_group_name]
          description                  = options[:description]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::CreateClusterSecurityGroup.new
          }

          params[:query]['Action']                   = 'CreateClusterSecurityGroup'
          params[:query]['ClusterSecurityGroupName'] = cluster_security_group_name if cluster_security_group_name
          params[:query]['Description']              = description if description

          request(params)
        end
      end
    end
  end
end
