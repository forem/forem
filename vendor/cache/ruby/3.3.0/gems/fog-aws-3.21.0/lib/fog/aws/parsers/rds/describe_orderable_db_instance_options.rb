module Fog
  module Parsers
    module AWS
      module RDS
        class DescribeOrderableDBInstanceOptions < Fog::Parsers::Base
          def reset
            @response = { 'DescribeOrderableDBInstanceOptionsResult' => {'OrderableDBInstanceOptions' => []}, 'ResponseMetadata' => {} }
            @db_instance_option = {}
            @db_instance_options = []
          end

          def start_element(name, attrs = [])
            case name
            when 'AvailabilityZones' then @availability_zones = []
            when 'AvailabilityZone' then @availability_zone = {}
            end
            super
          end

          def end_element(name)
            case name
            when 'MultiAZCapable', 'ReadReplicaCapable', 'Vpc', 'SupportsIops',
                 'SupportsEnhancedMonitoring', 'SupportsIAMDatabaseAuthentication',
                 'SupportsPerformanceInsights', 'SupportsStorageEncryption' then @db_instance_option[name] = to_boolean(value)
            when 'Engine', 'LicenseModel', 'EngineVersion', 'DBInstanceClass', 'StorageType' then @db_instance_option[name] = value
            when 'AvailabilityZones' then @db_instance_option[name] = @availability_zones
            when 'AvailabilityZone' then @availability_zones << @availability_zone unless @availability_zone.empty?
            when 'Name' then @availability_zone[name] = value
            when 'OrderableDBInstanceOption'
              @db_instance_options << @db_instance_option
              @db_instance_option = {}
            when 'OrderableDBInstanceOptions'
              @response['DescribeOrderableDBInstanceOptionsResult']['OrderableDBInstanceOptions'] = @db_instance_options
            when 'Marker' then @response['DescribeOrderableDBInstanceOptionsResult'][name] = value
            when 'RequestId' then @response['ResponseMetadata'][name] = value
            end
          end

          def to_boolean(v)
            (v =~ /\A\s*(true|yes|1|y)\s*$/i) == 0
          end
        end
      end
    end
  end
end
