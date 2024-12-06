module Fog
  module AWS
    class Redshift
      class Real
        require 'fog/aws/parsers/redshift/describe_cluster_snapshots'

        # ==== Parameters
        #
        # @param [Hash] options
        # * :cluster_identifier - (String)
        #    The identifier of the cluster for which information about snapshots is requested.
        # * :snapshot_identifier - (String)
        #    The snapshot identifier of the snapshot about which to return information.
        # * :snapshot_type - (String)
        #    The type of snapshots for which you are requesting information. By default,
        #    snapshots of all types are returned. Valid Values: automated | manual
        # * :start_time - (String)
        #    A value that requests only snapshots created at or after the specified time.
        #    The time value is specified in ISO 8601 format. For more information about
        #    ISO 8601, go to the ISO8601 Wikipedia  page. Example: 2012-07-16T18:00:00Z
        # * :end_time - (String)
        #    A time value that requests only snapshots created at or before the specified
        #    time. The time value is specified in ISO 8601 format. For more information
        #    about ISO 8601, go to the ISO8601 Wikipedia page. Example: 2012-07-16T18:00:00Z
        # * :owner_account - (String)
        #    The AWS customer account used to create or copy the snapshot. Use this field to
        #    filter the results to snapshots owned by a particular account. To describe snapshots
        #    you own, either specify your AWS customer account, or do not specify the parameter.
        # * :max_records - (Integer)
        #    The maximum number of records to include in the response. If more than the
        #    MaxRecords value is available, a marker is included in the response so that the
        #    following results can be retrieved. Constrained between [20,100]. Default is 100.
        # * :marker - (String)
        #    The marker returned from a previous request. If this parameter is specified, the
        #    response includes records beyond the marker only, up to MaxRecords.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/redshift/latest/APIReference/API_DescribeClusterSnapshots.html
        def describe_cluster_snapshots(options = {})
          cluster_identifier  = options[:cluster_identifier]
          snapshot_identifier = options[:snapshot_identifier]
          start_time          = options[:start_time]
          end_time            = options[:end_time]
          owner_account       = options[:owner_account]
          marker              = options[:marker]
          max_records         = options[:max_records]

          path = "/"
          params = {
            :idempotent => true,
            :headers    => {},
            :path       => path,
            :method     => :get,
            :query      => {},
            :parser     => Fog::Parsers::Redshift::AWS::DescribeClusterSnapshots.new
          }

          params[:query]['Action']             = 'DescribeClusterSnapshots'
          params[:query]['ClusterIdentifier']  = cluster_identifier if cluster_identifier
          params[:query]['SnapshotIdentifier'] = snapshot_identifier if snapshot_identifier
          params[:query]['start_time']         = start_time if start_time
          params[:query]['end_time']           = end_time if end_time
          params[:query]['OwnerAccount']       = owner_account if owner_account
          params[:query]['Marker']             = marker if marker
          params[:query]['MaxRecords']         = max_records if max_records

          request(params)
        end
      end
    end
  end
end
