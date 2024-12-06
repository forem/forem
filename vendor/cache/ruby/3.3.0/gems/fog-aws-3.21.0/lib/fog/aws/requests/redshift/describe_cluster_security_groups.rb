module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_cluster_security_groups'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_security_group_name - (String)
        #    The name of a cluster security group for which you are requesting details. You
        #    can specify either the Marker parameter or a ClusterSecurityGroupName parameter,
        #    but not both. Example: securitygroup1
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeClusterSecurityGroups.html
        def describe_cluster_security_groups(options = {})
          cluster_security_group_name  = options[:cluster_security_group_name]
          marker                       = options[:marker]
          max_records                  = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeClusterSecurityGroups.new
          }

          params[:query]['Action']                   = 'DescribeClusterSecurityGroups'
          params[:query]['ClusterSecurityGroupName'] = cluster_security_group_name if cluster_security_group_name
          params[:query]['Marker']                   = marker if marker
          params[:query]['MaxRecords']               = max_records if max_records

          request(params)
        end
      end
    end
  end
end
