module Fog
  module Parsers
    module AWS
      module CloudWatch
        class ListMetrics < Fog::Parsers::Base
          def reset
            @response = { 'ListMetricsResult' => {'Metrics' => []}, 'ResponseMetadata' => {} }
            reset_metric
          end

          def reset_metric
            @metric = {'Dimensions' => []}
          end

          def reset_dimension
            @dimension = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Dimensions'
              @in_dimensions = true
            when 'member'
              if @in_dimensions
                reset_dimension
              end
            end
          end

          def end_element(name)
            case name
            when 'Name', 'Value'
              @dimension[name] = value
            when 'Namespace', 'MetricName'
              @metric[name] = value
            when 'Dimensions'
              @in_dimensions = false
            when 'NextMarker', 'NextToken'
              @response['ListMetricsResult'][name] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            when 'member'
              if !@in_dimensions
                @response['ListMetricsResult']['Metrics'] << @metric
                reset_metric
              else
                @metric['Dimensions'] << @dimension
              end
            end
          end
        end
      end
    end
  end
end
