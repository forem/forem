module Fog
  module AWS
    class Redshift
      class Real
        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_security_group_name - required - (String)
        #    The name of the cluster security group to be deleted.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DeleteClusterSecurityGroup.html
        def delete_cluster_security_group(options = {})
          cluster_security_group_name = options[:cluster_security_group_name]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {}
          }

          params[:query]['Action']                     = 'DeleteClusterSecurityGroup'
          params[:query]['ClusterSecurityGroupName']   = cluster_security_group_name if cluster_security_group_name

          request(params)
        end
      end
    end
  end
end
