module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/download_db_logfile_portion'

        # Retrieve a portion of a log file of a db instance
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/API_DownloadDBLogFilePortion.html
        # ==== Parameters
        # * DBInstanceIdentifier <~String> - ID of instance to retrieve information for. Required.
        # * LogFileName <~String> - The name of the log file to be downloaded. Required.
        # * Options <~Hash> - Hash of options. Optional. The following keys are used:
        #   * :marker <~String> - The pagination token provided in the previous request. If this parameter is specified the response includes only records beyond the marker, up to MaxRecords. Optional.
        #   * :max_records <~Integer> - The maximum number of records to include in the response. If more records exist, a pagination token is included in the response. Optional.
        #   * :number_of_lines <~Integer> - The number of lines to download. Optional.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def download_db_logfile_portion(identifier=nil, filename=nil, opts={})
          params = {}
          params['DBInstanceIdentifier'] = identifier if identifier
          params['LogFileName'] = filename if filename
          params['Marker'] = opts[:marker] if opts[:marker]
          params['MaxRecords'] = opts[:max_records] if opts[:max_records]
          params['NumberOfLines'] = opts[:number_of_lines] if opts[:number_of_lines]

          request({
            'Action'  => 'DownloadDBLogFilePortion',
            :parser   => Fog::Parsers::AWS::RDS::DownloadDBLogFilePortion.new
          }.merge(params))
        end
      end

      class Mock
        def download_db_logfile_portion(identifier=nil, filename=nil, opts={})
          response = Excon::Response.new
          server_set = []
          if identifier
            if server = self.data[:servers][identifier]
              server_set << server
            else
              raise Fog::AWS::RDS::NotFound.new("DBInstance #{identifier} not found")
            end
          else
            server_set = self.data[:servers].values
          end

          response.status = 200
          response.body = {
              "ResponseMetadata" => { "RequestId"=> Fog::AWS::Mock.request_id },
              "DescribeDBInstancesResult" => { "DBInstances" => server_set }
          }
          response
        end
      end
    end
  end
end
