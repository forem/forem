module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_events'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :source_identifier - (String)
        #    The identifier of the event source for which events will be returned. If this
        #    parameter is not specified, then all sources are included in the response.
        #    Constraints: If SourceIdentifier is supplied, SourceType must also be provided.
        #    Specify a cluster identifier when SourceType is cluster. Specify a cluster security
        #    group name when SourceType is cluster-security-group. Specify a cluster parameter
        #    group name when SourceType is cluster-parameter-group. Specify a cluster snapshot
        #    identifier when SourceType is cluster-snapshot.
        # * :source_type - (String)
        #    The event source to retrieve events for. If no value is specified, all events are
        #    returned. Constraints: If SourceType is supplied, SourceIdentifier must also be
        #    provided. Specify cluster when SourceIdentifier is a cluster identifier. Specify
        #    cluster-security-group when SourceIdentifier is a cluster security group name. Specify
        #    cluster-parameter-group when SourceIdentifier is a cluster parameter group name. Specify
        #    cluster-snapshot when SourceIdentifier is a cluster snapshot identifier. Valid values
        #    include: cluster, cluster-parameter-group, cluster-security-group, cluster-snapshot
        # * :start_time - (String<)
        #    The beginning of the time interval to retrieve events for, specified in ISO 8601
        #    format. Example: 2009-07-08T18:00Z
        # * :end_time - (String<)
        #    The end of the time interval for which to retrieve events, specified in ISO 8601
        #    format. Example: 2009-07-08T18:00Z
        # * :duration - (Integer)
        #    The number of minutes prior to the time of the request for which to retrieve events.
        #    For example, if the request is sent at 18:00 and you specify a duration of 60, then
        #    only events which have occurred after 17:00 will be returned. Default: 60
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeEvents.html
        def describe_events(options = {})
          source_identifier = options[:source_identifier]
          source_type       = options[:source_type]
          start_time        = options[:start_time]
          end_time          = options[:end_time]
          duration          = options[:duration]
          marker            = options[:marker]
          max_records       = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeEvents.new
          }

          params[:query]['Action']           = 'DescribeEvents'
          params[:query]['SourceIdentifier'] = source_identifier if source_identifier
          params[:query]['SourceType']       = source_type if source_type
          params[:query]['StartTime']        = start_time if start_time
          params[:query]['EndTime']          = end_time if end_time
          params[:query]['Duration']         = duration if duration
          params[:query]['Marker']           = marker if marker
          params[:query]['MaxRecords']       = max_records if max_records

          request(params)
        end
      end
    end
  end
end
