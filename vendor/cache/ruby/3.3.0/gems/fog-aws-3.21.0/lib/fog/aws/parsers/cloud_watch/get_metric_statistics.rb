module Fog
  module Parsers
    module AWS
      module CloudWatch
        class GetMetricStatistics < Fog::Parsers::Base
          def reset
            @response = { 'GetMetricStatisticsResult' => {'Datapoints' => []}, 'ResponseMetadata' => {} }
            reset_datapoint
          end

          def reset_datapoint
            @datapoint = {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'Average', 'Maximum', 'Minimum', 'SampleCount', 'Sum'
              @datapoint[name] = value.to_f
            when 'Unit'
              @datapoint[name] = value
            when 'Timestamp'
              @datapoint[name] = Time.parse value
            when 'member'
              @response['GetMetricStatisticsResult']['Datapoints'] << @datapoint
              reset_datapoint
            when 'Label'
              @response['GetMetricStatisticsResult'][name] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
