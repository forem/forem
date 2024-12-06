module Fog
  module AWS
    class Redshift
      class Real
        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_subnet_group_name - required - (String)
        #    The name for the subnet group. Amazon Redshift stores the value as a lowercase string.
        #    Constraints: Must contain no more than 255 alphanumeric characters or hyphens. Must not
        #    be "Default". Must be unique for all subnet groups that are created by your AWS account.
        #    Example: examplesubnetgroup
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DeleteClusterSubnetGroup.html
        def delete_cluster_subnet_group(options = {})
          cluster_subnet_group_name = options[:cluster_subnet_group_name]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :delete,
            :query      => {}
          }

          params[:query]['Action']                 = 'DeleteClusterSubnetGroup'
          params[:query]['ClusterSubnetGroupName'] = cluster_subnet_group_name if cluster_subnet_group_name

          request(params)
        end
      end
    end
  end
end
