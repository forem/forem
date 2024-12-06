module Fog
  module Parsers
    module AWS
      module DNS
        class ListResourceRecordSets < Fog::Parsers::Base
          def reset
            @resource_record = []
            @resource_record_set = {}
            @resource_record_set['ResourceRecords'] = []
            @alias_target = {}
            @geo_location = {}
            @response = {}
            @response['ResourceRecordSets'] = []
            @section = :resource_record_set
          end

          def end_element(name)
            if @section == :resource_record_set
              case name
              when 'Type', 'TTL', 'SetIdentifier', 'Weight', 'Region', 'HealthCheckId', 'Failover'
                @resource_record_set[name] = value
              when 'Name'
                @resource_record_set[name] = value.gsub('\\052', '*')
              when 'Value'
                @resource_record_set['ResourceRecords'] << value
              when 'AliasTarget'
                @resource_record_set[name] = @alias_target
                @alias_target = {}
              when 'HostedZoneId', 'DNSName', 'EvaluateTargetHealth'
                @alias_target[name] = value
              when 'GeoLocation'
                @resource_record_set[name] = @geo_location
                @geo_location = {}
              when 'ContinentCode', 'CountryCode', 'SubdivisionCode'
                @geo_location[name] = value
              when 'ResourceRecordSet'
                @response['ResourceRecordSets'] << @resource_record_set
                @resource_record_set = {}
                @resource_record_set['ResourceRecords'] = []
              when 'ResourceRecordSets'
                @section = :main
              end
            elsif @section == :main
              case name
              when 'MaxItems'
                @response[name] = value.to_i
              when 'NextRecordName', 'NextRecordType', 'NextRecordIdentifier'
                @response[name] = value
              when 'IsTruncated'
                @response[name] = value == 'true'
              end
            end
          end
        end
      end
    end
  end
end
