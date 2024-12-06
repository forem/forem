module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_cluster_parameters'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :parameter_group_name - required - (String)
        #    The name of a cluster parameter group for which to return details.
        # * :source - (String)
        #    The parameter types to return. Specify user to show parameters that are
        #    different form the default. Similarly, specify engine-default to show parameters
        #    that are the same as the default parameter group. Default: All parameter types
        #    returned. Valid Values: user | engine-default
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeClusterParameters.html
        def describe_cluster_parameters(options = {})
          parameter_group_name = options[:parameter_group_name]
          source               = options[:source]
          marker               = options[:marker]
          max_records          = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeClusterParameters.new
          }

          params[:query]['Action']             = 'DescribeClusterParameters'
          params[:query]['ParameterGroupName'] = parameter_group_name if parameter_group_name
          params[:query]['Source']             = source if source
          params[:query]['Marker']             = marker if marker
          params[:query]['MaxRecords']         = max_records if max_records

          request(params)
        end
      end
    end
  end
end
