module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/event_list'

        # Returns a list of service events
		#
        # For more information see:
		# http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeEvents.html
		#
        # === Parameters (optional)
        # * options <~Hash> (optional):
        # *  :start_time <~DateTime> - starting time for event records
        # *  :end_time <~DateTime> - ending time for event records
        # *  :duration <~Integer> - The number of minutes to retrieve events for
		#			Default = 60 Mins
        # *  :marker <~String> - marker provided in the previous request
        # *  :max_records <~Integer> - the maximum number of records to include
		#			Default = 100
		#			Constraints: min = 20, maximum 100
        # *  :source_identifier <~String> - identifier of the event source
        # *  :source_type <~DateTime> - event type, one of:
        #      (db-instance | db-parameter-group | db-security-group | db-snapshot)
        # === Returns
        # * response <~Excon::Response>:
        #   * body <~Hash>
        def describe_events(options = {})
          request(
            'Action'            => 'DescribeEvents',
            'StartTime'         => options[:start_time],
            'EndTime'           => options[:end_time],
            'Duration'          => options[:duration],
            'Marker'            => options[:marker],
            'MaxRecords'        => options[:max_records],
            'SourceIdentifier'  => options[:source_identifier],
            'SourceType'        => options[:source_type],
            :parser => Fog::Parsers::AWS::RDS::EventListParser.new
          )
        end
      end

      class Mock
        def describe_events
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
