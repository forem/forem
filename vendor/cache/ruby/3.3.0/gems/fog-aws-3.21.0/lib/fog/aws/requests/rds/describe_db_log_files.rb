module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/describe_db_log_files'

        # Describe log files for a DB instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DescribeDBLogFiles.html
        # ==== Parameters
        # * DBInstanceIdentifier <~String> - ID of instance to retrieve information for. Required.
        # * Options <~Hash> - Hash of options. Optional. The following keys are used:
        #   * :file_last_written <~Long> - Filter available log files for those written after this time. Optional.
        #   * :file_size <~Long> - Filters the available log files for files larger than the specified size. Optional.
        #   * :filename_contains <~String> - Filters the available log files for log file names that contain the specified string. Optional.
        #   * :marker <~String> - The pagination token provided in the previous request. If this parameter is specified the response includes only records beyond the marker, up to MaxRecords. Optional.
        #   * :max_records <~Integer> - The maximum number of records to include in the response. If more records exist, a pagination token is included in the response. Optional.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def describe_db_log_files(rds_id=nil, opts={})
          params = {}
          params['DBInstanceIdentifier'] = rds_id if rds_id
          params['Marker'] = opts[:marker] if opts[:marker]
          params['MaxRecords'] = opts[:max_records] if opts[:max_records]
          params['FilenameContains'] = opts[:filename_contains] if opts[:filename_contains]
          params['FileSize'] = opts[:file_size] if opts[:file_size]
          params['FileLastWritten'] = opts[:file_last_written] if opts[:file_last_written]

          request({
            'Action'  => 'DescribeDBLogFiles',
            :parser   => Fog::Parsers::AWS::RDS::DescribeDBLogFiles.new(rds_id)
          }.merge(params))
        end
      end

      class Mock
        def describe_db_log_files(rds_id=nil, opts={})
          response = Excon::Response.new
          log_file_set = []

          if rds_id
            if server = self.data[:servers][rds_id]
              log_file_set << {"LastWritten" => Time.parse('2013-07-05 17:00:00 -0700'), "LogFileName" => "error/mysql-error.log", "Size" => 0}
              log_file_set << {"LastWritten" => Time.parse('2013-07-05 17:10:00 -0700'), "LogFileName" => "error/mysql-error-running.log", "Size" => 0}
              log_file_set << {"LastWritten" => Time.parse('2013-07-05 17:20:00 -0700'), "LogFileName" => "error/mysql-error-running.log.0", "Size" => 8220}
              log_file_set << {"LastWritten" => Time.parse('2013-07-05 17:30:00 -0700'), "LogFileName" => "error/mysql-error-running.log.1", "Size" => 0}
            else
              raise Fog::AWS::RDS::NotFound.new("DBInstance #{rds_id} not found")
            end
          else
            raise Fog::AWS::RDS::NotFound.new('An identifier for an RDS instance must be provided')
          end

          response.status = 200
          response.body = {
              "ResponseMetadata" => { "RequestId" => Fog::AWS::Mock.request_id },
              "DescribeDBLogFilesResult" => { "DBLogFiles" => log_file_set }
          }
          response
        end
      end
    end
  end
end
