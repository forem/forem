module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_clusters'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_identifier - (String)
        #    The unique identifier of a cluster whose properties you are requesting.
        #    This parameter isn't case sensitive. The default is that all clusters
        #    defined for an account are returned.
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeClusters.html
        def describe_clusters(options = {})
          cluster_identifier = options[:cluster_identifier]
          marker             = options[:marker]
          max_records        = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeClusters.new
          }

          params[:query]['Action']            = 'DescribeClusters'
          params[:query]['ClusterIdentifier'] = cluster_identifier if cluster_identifier
          params[:query]['MaxRecords']        = max_records if max_records
          params[:query]['Marker']            = marker if marker

          request(params)
        end
      end
    end
  end
end
