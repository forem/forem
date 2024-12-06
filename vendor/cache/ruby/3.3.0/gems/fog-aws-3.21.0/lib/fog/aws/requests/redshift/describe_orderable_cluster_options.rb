module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_orderable_cluster_options'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_version - (String)
        #    The version filter value. Specify this parameter to show only the available
        #    offerings matching the specified version. Default: All versions. Constraints:
        #    Must be one of the version returned from DescribeClusterVersions.
        # * :node_type - (String)
        #    The node type filter value. Specify this parameter to show only the available
        #    offerings matching the specified node type.
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeOrderableClusterOptions.html
        def describe_orderable_cluster_options(options = {})
          cluster_version = options[:cluster_version]
          node_type       = options[:node_type]
          marker          = options[:marker]
          max_records     = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeOrderableClusterOptions.new
          }

          params[:query]['Action']         = 'DescribeOrderableClusterOptions'
          params[:query]['ClusterVersion'] = cluster_version if cluster_version
          params[:query]['NodeType']       = node_type if node_type
          params[:query]['Marker']         = marker if marker
          params[:query]['MaxRecords']     = max_records if max_records

          request(params)
        end
      end
    end
  end
end
