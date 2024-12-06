module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_cluster_versions'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_parameter_group_family - (String)
        #    The name of a specific cluster parameter group family to return details for.
        #    Constraints: Must be 1 to 255 alphanumeric characters. First character must be
        #    a letter, and cannot end with a hyphen or contain two consecutive hyphens.
        # * :cluster_version - (String)
        #    The specific cluster version to return. Example: 1.0
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeClusterVersions.html
        def describe_cluster_versions(options = {})
          cluster_version                = options[:cluster_version]
          cluster_parameter_group_family = options[:cluster_parameter_group_family]
          marker                         = options[:marker]
          max_records                    = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeClusterVersions.new
          }

          params[:query]['Action']                      = 'DescribeClusterVersions'
          params[:query]['ClusterVersion']              = cluster_version if cluster_version
          params[:query]['ClusterParameterGroupFamily'] = cluster_parameter_group_family if cluster_parameter_group_family
          params[:query]['Marker']                      = marker if marker
          params[:query]['MaxRecords']                  = max_records if max_records

          request(params)
        end
      end
    end
  end
end
