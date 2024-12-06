module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/cluster'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_identifier - required - (String)
        #    A unique identifier for the cluster. You use this identifier to refer to the cluster
        #    for any subsequent cluster operations such as deleting or modifying. Must be unique
        #    for all clusters within an AWS account. Example: myexamplecluster
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DeleteCluster.html
        def reboot_cluster(options = {})
          cluster_identifier = options[:cluster_identifier]

          path = "/"
          params = {
            :headers    => {},
            :path       => path,
            :method     => :put,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::Cluster.new
          }

          params[:query]['Action']                           = 'RebootCluster'
          params[:query]['ClusterIdentifier']                = cluster_identifier if cluster_identifier
          request(params)
        end
      end
    end
  end
end
