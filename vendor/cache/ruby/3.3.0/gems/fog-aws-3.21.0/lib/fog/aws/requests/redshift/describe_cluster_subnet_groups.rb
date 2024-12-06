module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_cluster_subnet_groups'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_subnet_group_name - (String)
        #    The name of the cluster subnet group for which information is requested.
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeClusterSubnetGroups.html
        def describe_cluster_subnet_groups(cluster_subnet_group_name=nil, marker=nil,max_records=nil)
          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeClusterSubnetGroups.new
          }

          params[:query]['Action']                 = 'DescribeClusterSubnetGroups'
          params[:query]['ClusterSubnetGroupName'] = cluster_subnet_group_name if cluster_subnet_group_name
          params[:query]['Marker']                 = marker if marker
          params[:query]['MaxRecords']             = max_records if max_records

          request(params)
        end
      end
    end
  end
end
