module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeMetricCollectionTypes < Fog::Parsers::Base
          def reset
            reset_granularity
            reset_metric
            @results = { 'Granularities' => [], 'Metrics' => [] }
            @response = { 'DescribeMetricCollectionTypesResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_granularity
            @granularity = {}
          end

          def reset_metric
            @metric = {}
          end

          def start_element(name, attrs = [])
            super

            case name
            when 'Granularities'
              @in_granularities = true
            when 'Metrics'
              @in_metrics = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_granularities
                @results['Granularities'] << @granularity
                reset_granularity
              elsif @in_metrics
                @results['Metrics'] << @metric
                reset_metric
              end

            when 'Granularity'
               @granularity[name] = value
            when 'Granularities'
               @in_granularities = false

            when 'Metric'
               @metric[name] = value
            when 'Metrics'
               @in_metrics = false

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeMetricCollectionTypesResult'
              @response[name] = @results
            end
          end
        end
      end
    end
  end
end
