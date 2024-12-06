module Fog
  module Parsers
    module AWS
      module RDS
        class DescribeDBLogFiles < Fog::Parsers::Base
          attr_reader :rds_id

          def initialize(rds_id)
            @rds_id = rds_id
            super()
          end

          def reset
            @response = { 'DescribeDBLogFilesResult' => {'DBLogFiles' => []}, 'ResponseMetadata' => {} }
            fresh_log_file
          end

          def fresh_log_file
            @db_log_file = {'DBInstanceIdentifier' => @rds_id}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'LastWritten' then @db_log_file[name] = Time.at(value.to_i / 1000)
            when 'LogFileName' then @db_log_file[name] = value
            when 'Size' then @db_log_file[name] = value.to_i
            when 'DescribeDBLogFilesDetails'
              @response['DescribeDBLogFilesResult']['DBLogFiles'] << @db_log_file
              fresh_log_file
            when 'Marker' then @response['DescribeDBLogFilesResult'][name] = value
            when 'RequestId' then @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
