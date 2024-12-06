module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_default_cluster_parameters'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :parameter_group_family - required - (String)
        #    The name of a cluster parameter group family for which to return details.
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeDefaultClusterParameters.html
        def describe_default_cluster_parameters(options = {})
          parameter_group_family = options[:parameter_group_family]
          source                 = options[:source]
          marker                 = options[:marker]
          max_records            = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeDefaultClusterParameters.new
          }

          params[:query]['Action']               = 'DescribeDefaultClusterParameters'
          params[:query]['ParameterGroupFamily'] = parameter_group_family if parameter_group_family
          params[:query]['Marker']               = marker if marker
          params[:query]['MaxRecords']           = max_records if max_records

          request(params)
        end
      end
    end
  end
end
