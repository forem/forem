module Fog
  module AWS
    class RDS
      class Real
        require 'fog/aws/parsers/rds/restore_db_instance_to_point_in_time'

        # Restores a DB Instance to a point in time
        # http://docs.amazonwebservices.com/AmazonRDS/latest/APIReference/index.html?API_RestoreDBInstanceToPointInTime.html
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        def restore_db_instance_to_point_in_time(source_db_name, target_db_name, opts={})
          request({
            'Action'  => 'RestoreDBInstanceToPointInTime',
            'SourceDBInstanceIdentifier' => source_db_name,
            'TargetDBInstanceIdentifier' => target_db_name,
            :parser   => Fog::Parsers::AWS::RDS::RestoreDBInstanceToPointInTime.new,
          }.merge(opts))
        end
      end

      class Mock
        def restore_db_instance_to_point_in_time(source_db_name, target_db_name, opts={})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
